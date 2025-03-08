pipeline {
    agent any

    environment {
        VSPHERE_HOST = "vcenter.regional.miamioh.edu"
        VSPHERE_USER = ServiceUser('vsphere-credentials')  // vSphere credentials stored in Jenkins
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"  // Unique name using Jenkins build ID
        DATASTORE = "CITServer-Internal-2"
        RESOURCE_POOL = "/ClusterCIT"
        VM_FOLDER = "/Senior Project Machines"
        SSH_CREDENTIALS = credentials('gns3-credentials')  // Use stored Jenkins credentials
    }

    stages {
        stage('Clone VM from Running Machine') {
            steps {
                script {
                    sh """
                    govc vm.clone -vm $VM_SOURCE -ds $DATASTORE -folder $VM_FOLDER -pool $RESOURCE_POOL -on=false -name $NEW_VM_NAME
                    """
                }
            }
        }

        stage('Power On Cloned VM') {
            steps {
                script {
                    sh """
                    govc vm.power -on $NEW_VM_NAME
                    """
                }
            }
        }

        stage('Wait for VM to Boot') {
            steps {
                script {
                    echo "Waiting for VM to become reachable..."
                    sh "sleep 60"  // Adjust this as needed based on VM boot time
                }
            }
        }

        stage('Start GNS3 on Cloned VM') {
            steps {
                script {
                    def sshUser = SSH_CREDENTIALS.split(":")[0]
                    def sshPass = SSH_CREDENTIALS.split(":")[1]
                    sh """
                    sshpass -p '${sshPass}' ssh -o StrictHostKeyChecking=no ${sshUser}@$NEW_VM_NAME 'sudo systemctl start gns3server'
                    """
                }
            }
        }

        stage('Verify GNS3 API is Running') {
            steps {
                script {
                    sh """
                    curl --silent --fail http://$NEW_VM_NAME:3080/v2/version || exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            echo "GNS3 VM deployment successful: $NEW_VM_NAME"
        }
        failure {
            echo "Failed to deploy GNS3 VM."
        }
    }
}
