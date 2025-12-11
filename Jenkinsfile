
#------------------------------------------------------------------------------------------------------------------------------------
#------
pipeline {
    agent none
    
    environment {
        IMAGE_NAME = "christelleapp"
        IMAGE_TAG = "latest"
        CONTAINER_NAME = "christelleapp-container"
        HEROKU_APP_STAGING = "christelle-staging"
        HEROKU_APP_PRODUCTION = "christelle-production"
        HEROKU_API_KEY = credentials('heroku_api_key')
    }
    
    stages {
        stage('Build Image') {
            agent any
            steps {
                script {
                    echo "Building Docker image..."
                    sh '''
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }
        
        stage('Run Container') {
            agent any
            steps {
                script {
                    echo "Starting container..."
                    sh '''
                        # Stop and remove existing container if exists
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true
                        
                        # Run new container
                        docker run -d --name ${CONTAINER_NAME} -p 8000:5000 ${IMAGE_NAME}:${IMAGE_TAG}
                        
                        # Wait for container to be ready
                        sleep 5
                    '''
                }
            }
        }
        
        stage('Test Image') {
            agent any
            steps {
                script {
                    echo "Testing application with curl..."
                    sh '''
                        curl -f http://localhost:8000 || exit 1
                        echo "Test passed!"
                    '''
                }
            }
        }
        
        stage('Deploy to Heroku') {
            agent any
            when {
                branch 'master'
            }
            steps {
                script {
                    echo "Deploying to Heroku..."
                    sh '''
                        # Login to Heroku Container Registry
                        echo $HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com
                        
                        # Tag and push to staging
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${HEROKU_APP_STAGING}/web
                        docker push registry.heroku.com/${HEROKU_APP_STAGING}/web
                        
                        # Release staging
                        curl -X PATCH https://api.heroku.com/apps/${HEROKU_APP_STAGING}/formation \
                          -d '{"updates":[{"type":"web","docker_image":"'$(docker inspect registry.heroku.com/${HEROKU_APP_STAGING}/web --format={{.Id}})'"}]}' \
                          -H "Content-Type: application/json" \
                          -H "Accept: application/vnd.heroku+json; version=3.docker-releases" \
                          -H "Authorization: Bearer $HEROKU_API_KEY"
                        
                        # Tag and push to production
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${HEROKU_APP_PRODUCTION}/web
                        docker push registry.heroku.com/${HEROKU_APP_PRODUCTION}/web
                        
                        # Release production
                        curl -X PATCH https://api.heroku.com/apps/${HEROKU_APP_PRODUCTION}/formation \
                          -d '{"updates":[{"type":"web","docker_image":"'$(docker inspect registry.heroku.com/${HEROKU_APP_PRODUCTION}/web --format={{.Id}})'"}]}' \
                          -H "Content-Type: application/json" \
                          -H "Accept: application/vnd.heroku+json; version=3.docker-releases" \
                          -H "Authorization: Bearer $HEROKU_API_KEY"
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            agent any
            steps {
                script {
                    echo "Cleaning up..."
                    sh '''
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------