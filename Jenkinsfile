pipeline {
  agent { label 'jenkins-aws' }

  environment {
    DOCKER_IMAGE = "nihalpk/jenkins-demo"   // Docker Hub repo
  }

  options {
    skipDefaultCheckout(true)
    timestamps()
    disableConcurrentBuilds()
  }

  stages {

    /* =======================
       SOURCE CODE CHECKOUT
       ======================= */
    stage('Checkout') {
      steps {
        sh '''
          echo "📥 Cloning source code..."
          rm -rf jenkins-demo || true
          git clone https://github.com/Nihal106/jenkins-demo.git
        '''
      }
    }

    /* =======================
       BUILD APPLICATION
       ======================= */
    stage('Build') {
      steps {
        sh '''
          echo "🔨 Building application (skip tests)"
          cd jenkins-demo
          mvn -B clean package -DskipTests
        '''
      }
    }

    /* =======================
       PARALLEL QUALITY CHECKS
       ======================= */
    stage('Parallel Checks') {
      parallel {

        stage('Unit Tests') {
          steps {
            sh '''
              echo "🧪 Running unit tests"
              cd jenkins-demo
              mvn -B test
            '''
          }
        }

        stage('Static Checks') {
          steps {
            sh '''
              echo "🔍 Running static validation checks"
              cd jenkins-demo
              mvn -B validate
            '''
          }
        }
      }
    }

    /* =======================
       SONARQUBE SCAN
       ======================= */
    stage('SonarQube Scan') {
      steps {
        script {
          def scannerHome = tool 'sonar-scanner'
          withSonarQubeEnv('sonarqube') {
            sh """
              echo "🔐 Running SonarQube scan"
              export PATH=${scannerHome}/bin:\$PATH
              cd jenkins-demo
              sonar-scanner \
                -Dsonar.projectKey=jenkins-demo \
                -Dsonar.projectName=jenkins-demo \
                -Dsonar.sources=src \
                -Dsonar.java.binaries=target
            """
          }
        }
      }
    }

    /* =======================
       QUALITY GATE
       ======================= */
    stage('Quality Gate') {
      steps {
        echo "🚦 Waiting for Quality Gate result"
        timeout(time: 1, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    /* =======================
       DOCKER BUILD & PUSH
       ======================= */
    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            echo "🐳 Building & pushing Docker image"
            cd jenkins-demo

            docker login -u $DOCKER_USER -p $DOCKER_PASS

            docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} .
            docker tag $DOCKER_IMAGE:${BUILD_NUMBER} $DOCKER_IMAGE:latest

            docker push $DOCKER_IMAGE:${BUILD_NUMBER}
            docker push $DOCKER_IMAGE:latest
          '''
        }
      }
    }

    /* =======================
       TERRAFORM – PROVISION INFRA
       ======================= */
    stage('Terraform Apply') {
      steps {
        sh '''
          echo "🌍 Provisioning infrastructure using Terraform"
          cd jenkins-demo/terraform
          terraform init
          terraform apply -auto-approve
        '''
      }
    }

    /* =======================
       GENERATE ANSIBLE INVENTORY
       ======================= */
    stage('Generate Ansible Inventory') {
      steps {
        sh '''
          echo "📝 Generating Ansible inventory from Terraform output"
          cd jenkins-demo/terraform
          PUBLIC_IP=$(terraform output -raw app_server_public_ip)
          sed "s/\\${public_ip}/$PUBLIC_IP/" ../ansible/inventory.tpl > ../ansible/inventory
        '''
      }
    }

    /* =======================
       ANSIBLE CONFIGURATION
       ======================= */
    stage('Configure Server (Ansible)') {
      steps {
        sh '''
          echo "⚙️ Configuring server using Ansible"
          cd jenkins-demo/ansible
          ansible-playbook -i inventory deploy.yml
        '''
      }
    }
  }

  /* =======================
     POST ACTIONS
     ======================= */
  post {
    success {
      emailext(
        subject: "✅ SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
        body: """
Build Status : SUCCESS
Docker Image : ${DOCKER_IMAGE}:${BUILD_NUMBER}
Build URL    : ${BUILD_URL}
""",
        to: "nihalpk10006@gmail.com"
      )
    }

    failure {
      emailext(
        subject: "❌ FAILURE: ${JOB_NAME} #${BUILD_NUMBER}",
        body: """
Build Status : FAILED
Job Name     : ${JOB_NAME}
Build URL    : ${BUILD_URL}
""",
        to: "nihalpk10006@gmail.com"
      )
    }
  }
}
