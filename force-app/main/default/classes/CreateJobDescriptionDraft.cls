public with sharing class CreateJobDescriptionDraft {
    
    @InvocableMethod(label='Create Job Description Draft' description='Creates a job description draft for a position')
    public static List<Output> runProcess(List<Input> inputs){

        String positionId = inputs[0].recordId;
        Position__c position = [SELECT Id, Name__c, Name, Details__c FROM Position__c WHERE Id = :positionId];
       
        aiplatform.ModelsAPI.createGenerations_Request request = new aiplatform.ModelsAPI.createGenerations_Request();

        request.modelName = 'sfdc_ai__DefaultGPT5';

        // Create request body
        aiplatform.ModelsAPI_GenerationRequest requestBody = new aiplatform.ModelsAPI_GenerationRequest();
        request.body = requestBody;

        // Add prompt to body
        requestBody.prompt = 'Generate a job description draft for the position ' + position.Name + ' (' + position.Name__c + ') based on the following details: ' + position.Details__c;
        requestBody.prompt += 'The job description draft should be markdown format.';
        requestBody.prompt += 'Return only a JSON with the follwing format: { "title": "string", "jobDescription": "string" }';

        try {
            // Make request
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            aiplatform.ModelsAPI.createGenerations_Response response = modelsAPI.createGenerations(request);

            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.Code200.generation.generatedText);

            Output output = new Output();
            output.title = (String) responseMap.get('title');
            output.jobDescription = (String) responseMap.get('jobDescription');

            System.debug('##### title: ' + output.title);
            System.debug('##### jobDescription: ' + output.jobDescription);
            return new List<Output> { output };

        // Handle error
        } catch(aiplatform.ModelsAPI.createGenerations_ResponseException e) {
            System.debug('Response code: ' + e.responseCode);
            System.debug('The following exception occurred: ' + e);
        }

        return null;
   }

    
    public class Input {
        @InvocableVariable(required=true description='The Salesforce record id of the position')
        public String recordId;
    }

    public class Output {
        @InvocableVariable(description='The title of the job description')
        public String title;

        @InvocableVariable(description='The job description')
        public String jobDescription;
    }

}