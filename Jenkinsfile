pipeline {
    agent any

    environment {
        VSPHERE_HOST = "vcenter.regional.miamioh.edu"
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"  // Unique name using Jenkins build ID
        DATASTORE = "CITServer-Internal-2"
        RESOURCE_POOL = "/ClusterCIT"
        VM_FOLDER = "/Senior Project Machines"
    }

    stages {
    stage('Ensure govc Installed') {
        steps {
            script {
                sh """
                if ! command -v govc &> /dev/null; then
                echo "govc not found, installing..."
                curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz -o govc.tar.gz
                tar -xzf govc.tar.gz
                chmod +x govc
                sudo mv govc /usr/local/bin/govc
                rm govc.tar.gz
            fi
            """
        }
    }
}


        stage('Clone VM from Running Machine') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        govc vm.clone -vm $VM_SOURCE -ds $DATASTORE -folder $VM_FOLDER -pool $RESOURCE_POOL -on=false -name $NEW_VM_NAME \
                        -u "$VSPHERE_USER:$VSPHERE_PASS@$VSPHERE_HOST"
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
                        govc vm.power -on $NEW_VM_NAME -u "$VSPHERE_USER:$VSPHERE_PASS@$VSPHERE_HOST"
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
            echo "GNS3 VM deployment successful: $NEW_VM_NAME"
        }
        failure {
            echo "Failed to deploy GNS3 VM."
        }
    }
}
