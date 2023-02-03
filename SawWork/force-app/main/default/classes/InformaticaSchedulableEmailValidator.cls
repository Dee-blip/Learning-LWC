global class InformaticaSchedulableEmailValidator implements Schedulable {

    global void execute(SchedulableContext scMain) {
    	InformaticaEmailValidationJob job = new InformaticaEmailValidationJob();
    	ID idBatch = Database.executeBatch(job,10);
	}
}