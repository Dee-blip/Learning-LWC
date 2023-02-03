global class HD_Schedulable_AutomatedTicketAssignment implements Schedulable{ 
    global void execute(SchedulableContext sc){
        try{
            string status = HD_AutomatedTicketAssignment.assignOpenTickets();
            system.debug(status);
        }
        catch(exception e){
            system.debug(e.getMessage());
        }
    }

}