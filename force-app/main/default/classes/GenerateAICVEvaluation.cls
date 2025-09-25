public with sharing class GenerateAICVEvaluation {

    @InvocableMethod(label='Generate AI CV Evaluation Process' description='Launches the AI CV Evaluation Process')
    public static List<Output> runProcess(List<Input> inputs){
        Output output = new Output();
        output.success = true;
        Eventbus.publish(new AI_CV_Process_Request__e(Position_ID__c = inputs[0].recordId));
        return new List<Output> { output };
    }
    
    public class Input {
        @InvocableVariable(required=true description='The Salesforce record id of the position')
        public String recordId;
    }

    public class Output {
        @InvocableVariable(description='Whether the process was successful')
        public Boolean success;
    }

}