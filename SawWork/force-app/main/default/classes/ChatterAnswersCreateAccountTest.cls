@isTest(seeAllData=false)
private class ChatterAnswersCreateAccountTest {

	static testMethod void validateAccountCreation() {
		User dmlUser = new User(id=UserInfo.getUserId());

		User[] user = [SELECT Id, Firstname, Lastname from User where Id = :dmlUser.Id];
		// We cannot create account without a user.
		if (user.size() == 0) { return; }
		String firstName = user[0].FirstName;
		String lastName = user[0].LastName;
		String userId = user[0].Id;
		String accountId = new ChatterAnswers().createAccount(firstName, lastName, userId);
		Account account = [SELECT name, ownerId from Account where Id =: accountId];
		System.assertEquals(firstName + ' ' + lastName, account.name);
		System.assertEquals(userId, account.ownerId);
	}
}