@isTest(SeeAllData=true)
private class SupportEmployeeTest {
	static SupportEmployee supportEmployee;
    testmethod static void setPrimarySupportTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setPrimarySupport(10);
        System.assertEquals(10, supportEmployee.getPrimarySupport());        
    }
    testmethod static void setSecondarySupportTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setSecondarySupport(10);
        System.assertEquals(10, supportEmployee.getSecondarySupport());        
    }
    testmethod static void setOtherSupportTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setOtherSupport(10);
        System.assertEquals(10, supportEmployee.getOtherSupport());        
    }
    testmethod static void setPrimarySupportIdsTest(){
        supportEmployee = new SupportEmployee();
        Set<String> ids = new Set<String>();
        ids.add('id1');
        supportEmployee.setPrimarySupportIds(ids);
        System.assertEquals(ids, supportEmployee.getPrimarySupportIds());        
    }
    testmethod static void setSecondarySupportIdsTest(){
        supportEmployee = new SupportEmployee();
        Set<String> ids = new Set<String>();
        ids.add('id1');
        supportEmployee.setSecondarySupportIds(ids);
        System.assertEquals(ids, supportEmployee.getSecondarySupportIds());        
    }
    testmethod static void setOtherSupportIdsTest(){
        supportEmployee = new SupportEmployee();
        Set<String> ids = new Set<String>();
        ids.add('id1');
        supportEmployee.setOtherSupportIds(ids);
        System.assertEquals(ids, supportEmployee.getOtherSupportIds());        
    }
    testmethod static void setPrimaryAccCountTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setPrimaryAccCount(10);
        System.assertEquals(10, supportEmployee.getPrimaryAccCount());        
    }
    testmethod static void setSecondaryAccCountTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setSecondaryAccCount(10);
        System.assertEquals(10, supportEmployee.getSecondaryAccCount());        
    }
    testmethod static void setOtherAccCountTest(){
        supportEmployee = new SupportEmployee();
        supportEmployee.setOtherAccCount(10);
        System.assertEquals(10, supportEmployee.getOtherAccCount());        
    }

}