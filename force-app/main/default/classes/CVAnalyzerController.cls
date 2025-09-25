public with sharing class CVAnalyzerController {

    @AuraEnabled
    public static void analyzeCV(String blobString, String fileName, String positionId) {
        try {
            System.debug('Starting CV analysis for: ' + fileName);
            System.debug('Blob string: ' + blobString);
            System.debug('Blob String total characters: ' + blobString.length());
            System.debug('Position ID: ' + positionId);

            String requestBody = '{'+
                '"idpConfigurationIdOrName": "Resumes",'+
                '"files": ['+
                    '{'+
                        '"mimeType": "application/pdf",'+
                        '"data": "' + blobString + '"'+
                    '}'+
                ']'+
            '}';

            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint('callout:Data_Cloud_Document_AI');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(requestBody);
            request.setTimeout(120000); // 2 minutes timeout

            System.debug('makeAPICall: Sending HTTP request...');
            System.debug('makeAPICall: Request body size: ' + requestBody.length() + ' characters');

            HttpResponse response = http.send(request);

            System.debug('makeAPICall: Received HTTP response');
            System.debug('makeAPICall: Status Code: ' + response.getStatusCode());
            System.debug('makeAPICall: Response Headers: ' + response.getHeaderKeys());
            System.debug('makeAPICall: Response body size: ' + response.getBody().length() + ' characters');

            String documentAiResponse = '';

            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                System.debug('DOCUMENT AI: SUCCESS - API call successful');
                documentAiResponse = response.getBody();
            } else {
                System.debug('DOCUMENT AI: ERROR - API call failed');
                System.debug('DOCUMENT AI: Error response body: ' + response.getBody());
                throw new CalloutException('API call failed with status: ' + response.getStatusCode() +
                                        ', Body: ' + response.getBody());
            }

            Position__c position = [SELECT Id, Name__c, Job_Description_Details__c, Slack_Channel_Id__c
                                   FROM Position__c
                                   WHERE Id = :positionId];

            aiplatform.ModelsAPI.createGenerations_Request aiRequest = new aiplatform.ModelsAPI.createGenerations_Request();
            aiRequest.modelName = 'sfdc_ai__DefaultGPT5';

            // Create request body
            aiplatform.ModelsAPI_GenerationRequest aiRequestBody = new aiplatform.ModelsAPI_GenerationRequest();
            aiRequest.body = aiRequestBody;

            // Add prompt to body
            aiRequestBody.prompt = 'You are a technical interviewer and you are given a job description and a resume. You need to advise if the resume is a good fit for the job description. \n';
            aiRequestBody.prompt += 'Role: '+ position.Name__c +'\n\n';
            aiRequestBody.prompt += 'Job Description: '+ position.Job_Description_Details__c +'\n\n';
            aiRequestBody.prompt += 'Resume (JSON structure): '+documentAiResponse;

            try {
                // Make request
                aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
                aiplatform.ModelsAPI.createGenerations_Response aiResponse = modelsAPI.createGenerations(aiRequest);

                System.debug('####### MODELS API RESPONSE '+aiResponse.Code200.generation.generatedText);

                Eventbus.publish(new AI_CV_Processing_Complete__e(Position_ID__c = position.Id, 
                                                                    Slack_Channel_Id__c = position.Slack_Channel_Id__c,
                                                                    LLM_Response__c = aiResponse.Code200.generation.generatedText));

            } catch(aiplatform.ModelsAPI.createGenerations_ResponseException e) {
                System.debug('Response code: ' + e.responseCode);
                System.debug('The following exception occurred: ' + e);
            }

        } catch (Exception e) {
            System.debug('Error analyzing CV: ' + e.getMessage());
            throw new AuraHandledException('Analysis failed: ' + e.getMessage());
        }
    }
}