global class PACE_BatchSchedule implements schedulable {    
    global void execute(SchedulableContext sc)
    { 
        PACE_Batch ob = new PACE_Batch();
        Database.executeBatch(ob, 1);
    }
}