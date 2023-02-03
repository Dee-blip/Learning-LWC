global class InformaticaSchedulablePhoneValidator implements Schedulable {

    global void execute(SchedulableContext scMain) {
    	InformaticaPhoneValidationJob job = new InformaticaPhoneValidationJob();
    	ID idBatch = Database.executeBatch(job,10);
	}
}