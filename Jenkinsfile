pipeline {
    agent any

    environment {
        VSPHERE_HOST = "vcenter.regional.miamioh.edu"
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"
        DATASTORE = "CITServer-Internal-2"
        RESOURCE_POOL = "/ClusterCIT"
        VM_FOLDER = "/Senior Project Machines"
        SCRIPT_PATH = "/usr/src/app"  // Path where PowerShell scripts are stored
    }

    stages {
        stage('Set Up PowerCLI') {
            steps {
                script {
                    sh """
                    pwsh -c "if (!(Get-Module -ListAvailable VMware.PowerCLI)) { Install-Module -Name VMware.PowerCLI -Scope AllUsers -Force -AllowClobber }"
                    """
                }
            }
        }

        stage('Clone & Deploy VM') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        pwsh $SCRIPT_PATH/Deploy-GNS3.ps1 -vCenterServer "$VSPHERE_HOST" -vCenterUser "$VSPHERE_USER" -vCenterPass "$VSPHERE_PASS" -VMSource "$VM_SOURCE" -NewVMName "$NEW_VM_NAME" -Datastore "$DATASTORE" -ResourcePool "$RESOURCE_POOL" -VMFolder "$VM_FOLDER"
                        """
                    }
                }
            }
        }

        stage('Wait for VM to Boot') {
            steps {
                script {
                    echo "Waiting for VM to become reachable..."
                    sh "sleep 60"
                }
            }
        }
    }

    post {
        success {
            echo "✅ GNS3 VM deployment successful: $NEW_VM_NAME"
        }
        failure {
            echo "❌ Failed to deploy GNS3 VM."
        }
    }
}
