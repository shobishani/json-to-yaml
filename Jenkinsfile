// -*- mode: groovy -*-
// vim: set filetype=groovy :

podTemplate(
  containers: [
      containerTemplate(
        name: "gcloud",
        image: 'google/cloud-sdk:latest',
        ttyEnabled: true,
    )
  ],
  volumes: [ hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock'), ],
  ) {
properties([
  parameters([
    string(name: 'IMAGE_TAG', defaultValue: '', description: 'Select the branch to build. DEFAULT empty'),
    string(name: 'IMAGE_REPO', defaultValue: 'us.gcr.io/pypestream/json-to-yaml', description: 'Enter image repository url to push image. REQUIRED')
  ])
])

timeout(time: 2, unit: 'HOURS') {
    node(POD_LABEL) {
       def GIT_COMMIT_HASH
       container('gcloud'){
           notifyBuild("STARTED")
           cleanWs()
           checkout scm
           GIT_COMMIT_HASH = scmInfo.GIT_COMMIT[0..6]
           stage("Setup"){
               sh '''
                   set +x
                   apt-get update
                   apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
                   curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
                   add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
                   apt-get update && apt-get -y install docker-ce
                   apt-get update --fix-missing
                   apt-get install -y wget bzip2 unzip git ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1
                   apt-get install -y graphviz build-essential libpq-dev bash curl librdkafka-dev libssl-dev dirmngr libsnappy-dev
                   apt-get install -y --no-install-recommends python3-libarchive-c
                   apt-get install -y libgl1-mesa-glx
                   set -x
               '''
           }
           stage("Build") {
               withCredentials([
                   file(credentialsId: 'pypestream-deploy', variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
               ]) {
                   sh 'gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}'
                   sh "make package IMAGE_REPO=${IMAGE_REPO} IMAGE_TAG=${IMAGE_TAG}"
               }
           }
           stage("Deployment") {
                def CHART_PATH = 'etc/kubernetes/helm/json-to-yaml'
                def CHART_DETAIL = readYaml file: "${CHART_PATH}/Chart.yaml"
                CHART_DETAIL.version = "0.1.${BUILD_NUMBER}"
                def CHART_FILE_NAME = "${CHART_DETAIL.name}-${CHART_DETAIL.version}.tgz"
                CHART_DETAIL.appVersion = "${IMAGE_TAG}"
                if(env.TAG_NAME != null){
                    CHART_DETAIL.appVersion = env.TAG_NAME
                }
                sh "rm ${CHART_PATH}/Chart.yaml"
                writeYaml file: "${CHART_PATH}/Chart.yaml", data: CHART_DETAIL
                sh "make package-helm"
                sh "gsutil cp ${CHART_FILE_NAME} gs://deployment-artifacts/${CHART_FILE_NAME}"
                def SPINNAKER_WEBHOOK = "https://spinnaker-webhook-url"
                def SPINNAKER_PAYLOAD = JsonOutput.toJson([
                  artifacts: [
                    [
                      type: "gcs/object",
                      name: CHART_FILE_NAME,
                      reference: "gs://deployment-artifacts/${CHART_FILE_NAME}"
                    ]
                  ],
                  parameters: [
                    imageTag: CHART_DETAIL.appVersion,
                    repository: "${IMAGE_REPO}"
                  ]
                ])
                sh "curl -X POST ${SPINNAKER_WEBHOOK} \
                         -H 'Content-Type: application/json' \
                         -d '${SPINNAKER_PAYLOAD}'"
                notifyBuild("SUCCESSFUL")
           }
       }
    }
}

def notifyBuild(String buildStatus = 'STARTED') {
  buildStatus =  buildStatus ?: 'SUCCESSFUL'
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESSFUL') {
    color = 'GREEN'
    colorCode = '#00FF00'
    summary += ", Spinnaker deployment has been started"
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }
  slackSend (color: colorCode, message: summary)
}
