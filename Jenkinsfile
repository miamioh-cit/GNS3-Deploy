pipeline {
    agent any

    environment {
        VSPHERE_HOST = "vcenter.regional.miamioh.edu"
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"  // Unique name using Jenkins build ID
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

        stage('Connect to vSphere') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        pwsh -c "Connect-VIServer -Server $VSPHERE_HOST -User '$VSPHERE_USER' -Password '$VSPHERE_PASS'"
                        """
                    }
                }
            }
        }

        stage('Clone VM from Running Machine') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        pwsh $SCRIPT_PATH/Deploy-GNS3.ps1 -vCenter '$VSPHERE_HOST' -VMSource '$VM_SOURCE' -VMName '$NEW_VM_NAME' -Datastore '$DATASTORE' -ResourcePool '$RESOURCE_POOL' -VMFolder '$VM_FOLDER' -User '$VSPHERE_USER' -Password '$VSPHERE_PASS'
                        """
                    }
                }
            }
        }

        stage('Power On Cloned VM') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        pwsh -c "Start-VM -VM '$NEW_VM_NAME' -Confirm:\$false"
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
