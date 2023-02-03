global class MoveAccountPlansToFolderSchedular implements Schedulable {
    global void execute(SchedulableContext ctx) 
    {
        moveDocumentsToFolder();
    }
    
    @future(callout=true)
    public static void moveDocumentsToFolder(){
        MoveAccountPlansToExecutiveFolder moveToFolderAPICall = new MoveAccountPlansToExecutiveFolder();
        system.enqueueJob(moveToFolderAPICall);
    }
}