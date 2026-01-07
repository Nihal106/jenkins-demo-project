pipeline {
  agent { label 'jenkins-aws' }

  options {
    skipDefaultCheckout(true)   // manual checkout
    timestamps()
    disableConcurrentBuilds()
  }

  stages {

    stage('Checkout') {
      steps {
        sh '''
          echo "📥 Cloning source code on agent..."
          rm -rf jenkins-demo || true
          git clone https://github.com/Nihal106/jenkins-demo.git
          cd jenkins-demo
        '''
      }
    }

    stage('Build') {
      steps {
        sh '''
          echo "🔨 Building application (skip tests)"
          cd jenkins-demo
          mvn -B clean package -DskipTests
        '''
      }
    }

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

stage('SonarQube Scan') {
  steps {
    script {
      // Load Sonar Scanner tool into PATH
      def scannerHome = tool 'sonar-scanner'

      withSonarQubeEnv('sonarqube') {
        sh """
          echo "🔐 Running SonarQube scan (CLI)"
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



    stage('Quality Gate') {
      steps {
        echo "🚦 Waiting for Quality Gate result"
        timeout(time: 1, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          echo "🐳 Building Docker image"
          cd jenkins-demo
          docker build -t myapp:1.0 .
        '''
      }
    }
  }

  post {
    success {
      emailext(
        subject: "✅ SUCCESS: ${JOB_NAME} #${BUILD_NUMBER}",
        body: """
Build Status : SUCCESS
Job Name     : ${JOB_NAME}
Build Number : ${BUILD_NUMBER}
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
Build Number : ${BUILD_NUMBER}
Check Logs   : ${BUILD_URL}
""",
        to: "nihalpk10006@gmail.com"
      )
    }
  }
}
