pipeline {
    agent any

    environment {
        VSPHERE_HOST = "vcenter.regional.miamioh.edu"
        VM_SOURCE = "gns3-main"
        NEW_VM_NAME = "gns3-clone-${BUILD_ID}"  // Unique name using Jenkins build ID
        DATASTORE = "CITServer-Internal-2"
        RESOURCE_POOL = "/ClusterCIT"
        VM_FOLDER = "/Senior Project Machines"
        GOVC_PATH = "${WORKSPACE}/govc"  // Store govc in Jenkins workspace
    }

    stages {
        stage('Ensure govc Installed') {
            steps {
                script {
                    sh """
                    if [ ! -f "$GOVC_PATH" ]; then
                        echo "govc not found, installing..."
                        curl -L https://github.com/vmware/govmomi/releases/latest/download/govc_Linux_x86_64.tar.gz -o govc.tar.gz
                        tar -xzf govc.tar.gz
                        chmod +x govc
                        mv govc $GOVC_PATH
                        rm govc.tar.gz
                    else
                        echo "govc is already installed."
                    fi
                    """
                }
            }
        }

        stage('Verify govc Installation') {
            steps {
                script {
                    sh """
                    echo "Checking govc version..."
                    $GOVC_PATH version || {
                        echo "ERROR: govc is not executable!"
                        exit 1
                    }
                    """
                }
            }
        }

        stage('Clone VM from Running Machine') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'vsphere-credentials', usernameVariable: 'VSPHERE_USER', passwordVariable: 'VSPHERE_PASS')]) {
                    script {
                        sh """
                        export GOVC_URL="https://$VSPHERE_USER:$VSPHERE_PASS@$VSPHERE_HOST"
                        export GOVC_INSECURE=1
                        echo "Cloning VM..."
                        $GOVC_PATH vm.clone -vm $VM_SOURCE -ds $DATASTORE -folder $VM_FOLDER -pool $RESOURCE_POOL -on=false -name $NEW_VM_NAME || {
                            echo "ERROR: VM Clone failed!"
                            exit 1
                        }
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
                        export GOVC_URL="https://$VSPHERE_USER:$VSPHERE_PASS@$VSPHERE_HOST"
                        export GOVC_INSECURE=1
                        echo "Powering on VM..."
                        $GOVC_PATH vm.power -on $NEW_VM_NAME || {
                            echo "ERROR: Powering on VM failed!"
                            exit 1
                        }
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
