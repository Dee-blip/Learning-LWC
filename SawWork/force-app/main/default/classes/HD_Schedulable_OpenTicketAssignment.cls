global class HD_Schedulable_OpenTicketAssignment implements Schedulable {
    global void execute(SchedulableContext sc) 
    {
        System.debug('In execute of HD_Schedulable_OpenTicketAssignment');
      	try
        {
            HD_OpenTicketAssignment.assignOpenTickets();
     	}
        catch(Exception e)
        {
            System.debug('Error '+e);
        }
    }

}