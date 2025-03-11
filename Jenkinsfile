pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'roseaw/gns3deploy'
        DOCKER_IMAGE_TAG = 'latest'
        VCENTER_CREDENTIALS_ID = 'taylorw8-vsphere'
        VCENTER_SERVER = 'cit-vc.regionals.miamioh.edu'
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"
        DATASTORE = "CITServer-Internal-2"
        RESOURCE_POOL = "/ClusterCIT"
        VM_FOLDER = "/Senior Project Machines"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'roseaw-dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh """
                        docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        docker push ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Deploy GNS3 VM') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.VCENTER_CREDENTIALS_ID, usernameVariable: 'VCENTER_USER', passwordVariable: 'VCENTER_PASS')]) {
                        sh """
                        docker run --rm \
                            -e VCENTER_SERVER='${env.VCENTER_SERVER}' \
                            -e VCENTER_USER=\$VCENTER_USER \
                            -e VCENTER_PASS=\$VCENTER_PASS \
                            -e VM_SOURCE='${env.VM_SOURCE}' \
                            -e NEW_VM_NAME='${env.NEW_VM_NAME}' \
                            -e DATASTORE='${env.DATASTORE}' \
                            -e RESOURCE_POOL='${env.RESOURCE_POOL}' \
                            -e VM_FOLDER='${env.VM_FOLDER}' \
                            ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG} \
                            pwsh -File /usr/src/app/Deploy-GNS3.ps1 -vCenterServer '${env.VCENTER_SERVER}' -vCenterUser \$VCENTER_USER -vCenterPass \$VCENTER_PASS -VMSource '${env.VM_SOURCE}' -NewVMName '${env.NEW_VM_NAME}' -Datastore '${env.DATASTORE}' -ResourcePool '${env.RESOURCE_POOL}' -VMFolder '${env.VM_FOLDER}' -Verbose
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend color: "good", message: "✅ GNS3 VM Deployment Successful: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
        }
        unstable {
            slackSend color: "warning", message: "⚠️ GNS3 VM Deployment Unstable: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
        }
        failure {
            slackSend color: "danger", message: "❌ GNS3 VM Deployment Failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
        }
    }
}
