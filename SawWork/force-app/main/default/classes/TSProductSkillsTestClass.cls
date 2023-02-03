@isTest(SeeAllData=true)

public with sharing class TSProductSkillsTestClass {

	public static TS_Product_Skill__c skill1 = new TS_Product_Skill__c();
	public static TS_Product_Skill__c skill2 = new TS_Product_Skill__c();
	
	public static TS_ProductMember__c member1 = new TS_ProductMember__c();
	public static TS_ProductMember__c member2 = new TS_ProductMember__c();
	
	public static void initSkills()
	{
		skill1.Product_Skill_Name__c = 'Skill1 Name';
		skill1.Description__c = 'Skill1 Description';
		
		skill2.Product_Skill_Name__c = 'Skill2 Name';
		skill2.Description__c = 'Skill2 Description';
		
		insert skill1;
		insert skill2;
	}
	
	public static void initMembers()
	{
		User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1]; 
		member1.TS_Product_Skill__c = skill1.Id;
		member1.ProductMember__c = u1.Id;
		member1.Skill_Level__c = '2';		
		insert member1;
	}
	
	static testmethod void bulkInsertSkills()
	{
		List<TS_Product_Skill__c> skillList = new List<TS_Product_Skill__c>();
		for(Integer i=0;i<2;i++)
		{
			TS_Product_Skill__c skill = new TS_Product_Skill__c();
			skill.Product_Skill_Name__c = 'Skill ' + i;
			skill.Description__c = 'Desc ' + i;
			
			skillList.add(skill);
		}
		test.startTest();
		insert skillList;
		test.stopTest();
	}
	
	static testmethod void bulkInsertSKillMembers()
	{
		initSkills();
		User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];
		
		List<TS_ProductMember__c> memList = new List<TS_ProductMember__c>();
		TS_ProductMember__c mem1 = new TS_ProductMember__c();
		mem1.TS_Product_Skill__c = skill1.Id;
		mem1.ProductMember__c = u1.Id;
		mem1.Skill_Level__c = '2';
		memList.add(mem1);
		
		TS_ProductMember__c mem2 = new TS_ProductMember__c();
		mem2.TS_Product_Skill__c = skill2.Id;
		mem2.ProductMember__c = u1.Id;
		mem2.Skill_Level__c = '1';
		memList.add(mem2);
		
		test.startTest();
		insert memList;
		test.stopTest();
	}
	
	static testmethod void testProductSkillExtension()
	{
		PageReference pageRef = Page.TSProductSkillCreate;
		Test.setCurrentPage(pageRef);
		
		TS_Product_Skill__c skill = new TS_Product_Skill__c();
		skill.Product_Skill_Name__c = 'Skill Name';
		skill.Description__c = 'Skill Description';
		
		Apexpages.StandardController stdController = new Apexpages.StandardController(skill1);
		TSProductSkillExtension ext = new TSProductSkillExtension(stdController);	
		ext.save();
		List<PageMessages.PageMessage> msgList = PageMessages.getMessages();
		system.assert(msgList.size() < 1);
		
		PageReference ref = ext.skillsList();
		System.assertEquals('/apex/ACDEmployees', ref.getUrl());
	}
	
	static testmethod void testProductSkillListExt()
	{
		PageReference pageRef = new PageReference('/apex/TSTabset?sfdc.tabName=01rJ00000009RzP');
		Test.setCurrentPage(pageRef);
		Apexpages.StandardController stdController = new Apexpages.StandardController(skill1);
		TSProductSkillListExtension ext = new TSProductSkillListExtension(stdController);
		PageReference ref = ext.refresh();
		System.assertEquals('/apex/TSTabset', ref.getUrl());
		ref = ext.newSkill();
		System.assertEquals('/apex/TSProductSkillCreate', ref.getUrl());
		
		ext.userLabel = 'SSUDHEEN111,ABCDEF';
		User u = new User(alias = 'ssudheen');
		ext.loggedInUser = u;
		system.assertEquals(false, ext.getIsRendered());
		
		ext.userLabel = 'SSUDHEEN,ABCDEF';
		User actualLogin = new User();
        actualLogin=[Select Id,Name,Email,Alias from User where Id=:userinfo.getuserId()]; 
        if(actualLogin.Alias == 'SSUDHEEN')        
			system.assertEquals(true, ext.getIsRendered());
		else
			system.assertEquals(false, ext.getIsRendered());	
			
		initSkills();
		initMembers();
		pageRef = Page.TSProductSkillList;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('skillId', skill1.id);
		Apexpages.StandardController stdController1 = new Apexpages.StandardController(skill1);
		TSProductSkillListExtension ext1 = new TSProductSkillListExtension(stdController1);	
		ext1.getSkillMembers();
		System.assert(ext1.userList.size() > 0);	
		System.assert(!String.isBlank(ext1.skillName));
		
		ext1.getSkillMembersPoll();
		System.assert(ext1.userList.size() > 0);	
		System.assert(!String.isBlank(ext1.skillName));
		
		ext1.toBeDelMember = member1.Id;
		ext1.deleteMember();
		System.assert(ext1.userList.size() == 0);
		
		PageReference ref2 = ext1.newMember();
		System.assert(ref2.getUrl().contains('/apex/TSProductMemberCreate'));		
	}
	
	static testmethod void testProductMemberExtension() {
		PageReference pageRef = Page.TSProductMemberCreate;
		Test.setCurrentPage(pageRef);		
		User u = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1]; 
		ApexPages.currentPage().getParameters().put('userId', u.id);
		TS_ProductMember__c member = new TS_ProductMember__c();
		Apexpages.StandardController stdController = new Apexpages.StandardController(member);
		TSProductMemberExtension ext = new TSProductMemberExtension(stdController);
		member.TS_Product_Skill__c = skill1.Id;
		//ext.save();
		//system.assertEquals(null, ext.sucess);
        system.assertEquals(null, ext.save());
		
		member.ProductMember__c = u.Id;
		member.Skill_Level__c = '3';			
		system.assert(ext.getAllSkills().size() > 0);
		ext.selectedSkill = skill1.Id;
		ext.save();
		//system.assertEquals(true, ext.success);
		
		List<PageMessages.PageMessage> msgList = PageMessages.getMessages();
		system.assert(msgList.size() < 1);
		
		/*TS_ProductMember__c mem2 = new TS_ProductMember__c();
		Apexpages.StandardController stdController2 = new Apexpages.StandardController(mem2);
		TSProductMemberExtension ext2 = new TSProductMemberExtension(stdController2);
		mem2.TS_Product_Skill__c = skill1.Id;
		mem2.ProductMember__c = u.Id;
		mem2.Skill_Level__c = '3';
		ext.save();
		system.assertEquals(null, ext.success);	*/
        system.assertEquals(null, ext.save());	
		initSkills();
		pageRef = Page.TSProductMemberCreate;
		Test.setCurrentPage(pageRef);		
		u = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1]; 
		ApexPages.currentPage().getParameters().put('skillId', skill1.Id);	
		member = new TS_ProductMember__c();
		stdController = new Apexpages.StandardController(member);
		ext = new TSProductMemberExtension(stdController);
		member.TS_Product_Skill__c = skill1.Id;
		member.ProductMember__c = u.Id;
		member.Skill_Level__c = '3';
		ext.save();	
		system.assertEquals(true, ext.success);
	}
	
	static testmethod void testAgentIdExt()
	{		
		User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];
		Apexpages.StandardController stdController = new Apexpages.StandardController(u1);
		TSAgentIdExtension ext = new TSAgentIdExtension(stdController);
		u1.ACD_Agent_ID__c = '00001';
		System.runAs(u1) {
			ext.save();
		}
		u1 = [SELECT Id, ACD_Agent_ID__c FROM User WHERE alias='JACMACKE' LIMIT 1];
		system.assertEquals('00001', u1.ACD_Agent_ID__c);	
	}
}