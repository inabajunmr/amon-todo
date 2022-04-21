import { RemovalPolicy, Stack, StackProps } from 'aws-cdk-lib';
import { AmazonLinuxCpuType, AmazonLinuxGeneration, AmazonLinuxImage, Instance, InstanceClass, InstanceSize, InstanceType, Peer, Port, SecurityGroup, SubnetType, Vpc } from 'aws-cdk-lib/aws-ec2';
import { Cluster, ContainerImage, Secret as ECSSecret } from 'aws-cdk-lib/aws-ecs';
import { ApplicationLoadBalancedFargateService } from 'aws-cdk-lib/aws-ecs-patterns';
import { Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import { Credentials, DatabaseInstance, DatabaseInstanceEngine, MysqlEngineVersion } from 'aws-cdk-lib/aws-rds';
import { Secret } from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

export class CdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // VPC
    const vpc = new Vpc(this, 'vpc-amon-todo', {
      maxAzs: 2,
      natGateways: 0,
    })

    // RDS
    const rdsSecurityGroup = new SecurityGroup(this, 'rds-amon-todo-security-group', {
      vpc,
    });
    const rdsSecretName = 'rds-secret-amon-todo';
    const rdsCredentials = Credentials.fromGeneratedSecret('admin', { secretName: rdsSecretName });
    const rdsInstance = new DatabaseInstance(this, 'rds-amon-todo', {
      databaseName: 'amontodo',
      engine: DatabaseInstanceEngine.mysql({
        version: MysqlEngineVersion.VER_8_0_28
      }),
      credentials: rdsCredentials,
      instanceType: InstanceType.of(InstanceClass.BURSTABLE2, InstanceSize.SMALL),
      vpc,
      vpcSubnets: {
        subnetType: SubnetType.PRIVATE_ISOLATED,
      },
      removalPolicy: RemovalPolicy.DESTROY,
      deletionProtection: false,
      publiclyAccessible: false,
      securityGroups: [rdsSecurityGroup]
    });

    // EC2 for RDS Initialization
    const bastionSecurityGroup = new SecurityGroup(this, 'ec2-amon-todo-security-group', {
      vpc,
    });
    const myIp = scope.node.tryGetContext('MY_IP');
    bastionSecurityGroup.addIngressRule(Peer.ipv4(myIp + '/32'), Port.tcp(22));
    const instance = new Instance(this, 'ec2-amon-todo-bastion', {
      keyName: 'amon-todo',
      vpc,
      instanceType: InstanceType.of(
        InstanceClass.T2,
        InstanceSize.MICRO
      ),
      machineImage: new AmazonLinuxImage({
        generation: AmazonLinuxGeneration.AMAZON_LINUX_2,
        cpuType: AmazonLinuxCpuType.X86_64,
      }),
      vpcSubnets: {
        subnetType: SubnetType.PUBLIC,
      },
      securityGroup: bastionSecurityGroup
    });
    rdsSecurityGroup.addIngressRule(bastionSecurityGroup, Port.tcp(3306));
    const rdsSecretForBastion = Secret.fromSecretNameV2(this, 'rds-amon-todo-security-group-for-ec2-bastion', rdsSecretName);
    rdsSecretForBastion.grantRead(instance);

    // ECS
    const cluster = new Cluster(this, 'ecs-cluster-amon-todo', {
      vpc: vpc
    });

    // ECS Service & ALB
    const ecsServiceSecurityGroup = new SecurityGroup(this, 'ecs-service-amon-todo-security-group', {
      vpc,
    });
    const taskExecutionRole= new Role(this, 'taskExecutionRole', {assumedBy: new ServicePrincipal("ecs-tasks.amazonaws.com")});
    const rdsSecretForTaskExecutionRole = Secret.fromSecretNameV2(this, 'rds-amon-todo-security-group-for-task-execution-role', rdsSecretName);
    rdsSecretForTaskExecutionRole.grantRead(taskExecutionRole);
    const applicationLoadBalancedFargateService =
      new ApplicationLoadBalancedFargateService(this, 'ecs-service-amon-todo', {
        cluster: cluster,
        memoryLimitMiB: 1024,
        cpu: 512,
        taskImageOptions: {
          executionRole: taskExecutionRole,
          image: ContainerImage.fromRegistry('inabajunmr/amon-todo:latest'),
          environment: {
            DATABASE_HOST: rdsInstance.dbInstanceEndpointAddress,
            DATABASE_PORT: rdsInstance.dbInstanceEndpointPort,
            DATABASE_USERNAME: rdsCredentials.username,
            PLACK_ENV: 'production',
          },
          containerPort: 5000,
          secrets: {
            DATABASE_SECRET: ECSSecret.fromSecretsManager(rdsSecretForBastion, 'password')
          },
        },
        desiredCount: 1,
        assignPublicIp: true,
        securityGroups: [ecsServiceSecurityGroup],
        taskSubnets: {
          subnetType: SubnetType.PUBLIC,
        }
      });
      
    applicationLoadBalancedFargateService.targetGroup.configureHealthCheck({
      path: '/',
      healthyHttpCodes: '200-499'
    });
    rdsSecurityGroup.addIngressRule(ecsServiceSecurityGroup, Port.tcp(3306));
  }
}
