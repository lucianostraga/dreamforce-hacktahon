public with sharing class SaveJobDescription {
    
    @InvocableMethod(label='Save Job Description' description='Saves a job description for a position')
    public static List<Output> runProcess(List<Input> inputs){

        String positionId = inputs[0].recordId;

        Output output = new Output();
    
        try {
           update new Position__c(Id = positionId, 
           Job_Description_Details__c = inputs[0].jobDescription, 
           Job_Description_Title__c = inputs[0].title,
           Status__c = 'Open');

            output.success = true;
            return new List<Output> { output };

        // Handle error
        } catch(Exception e) {
            System.debug('Response code: ' + e.getMessage());
            System.debug('The following exception occurred: ' + e);
            output.success = false;
            return new List<Output> { output };
        }
   }

    
    public class Input {
        @InvocableVariable(required=true description='The Salesforce record id of the position')
        public String recordId;

        @InvocableVariable(required=true description='The title of the job description')
        public String title;

        @InvocableVariable(required=true description='The job description')
        public String jobDescription;
    }

    public class Output {
        @InvocableVariable(description='The title of the job description')
        public Boolean success;
    }

}