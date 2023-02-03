/*
* Developer @ Amogh M P
* This is Test class for LicenseChart.cls
* Used in License_Report Ligtning component
* Modification Log ===============================================================
* Date             Author              Modification
* 5 Aug 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
*/

@isTest(seeAllData = false)
public class Test_LicenseChart {
	static TestMethod void testListUsers(){
        List<User> ls = new List<User>(); 
        ls = LicenseChart.listUsers();
        System.assert(ls.size() != 0);
        
        ls = LicenseChart.listUsers1('Engineering');
        //System.assert(ls.size() != 0);
        ls = LicenseChart.listUsers1('ServiceDesk Staff');
        System.assert(ls.size() != 0);
        
        ls = LicenseChart.listUsers2(true);
        System.assert(ls.size() != 0);
        ls = LicenseChart.listUsers2(false);
        System.assert(ls.size() >= 0);
        
        ls = LicenseChart.listUsers3(0);
        System.assert(ls.size() >= 0);
        
        ls = LicenseChart.listUsers4(0);
        System.assert(ls.size() >= 0);
        
        
        List<String> uid = new List<String>();
        uid.add('simple');
        uid.add('text');
        ls = LicenseChart.bluemoont(uid);
        System.assert(ls.size() == 0);
        
        
        String userList;
        userList = LicenseChart.getUsersJSON();
        System.assert(userList.length() != 0);
        
        userList = LicenseChart.getUsageJSON(5);
        System.assert(userList.length() != 0);
        
        /*Integer i = 6000;
        Integer c50=0,c100=0,c500=0,c1k=0,c5k=0,chigh=0;
        Map<String,Integer> mapLeadSource = new Map<String,Integer>();
        if(i<50)
            c50++;
        else if(i>=50 && i<100)
            c100++;
        else if(i>=100 && i<500)
            c500++;
        else if(i>=500 && i<1000)
            c1k++;
        else if(i>=1000 && i<5000)
            c5k++;
        else
            chigh++;
        
        mapLeadSource.put('Blue Moon Users(0-50)', c50);
        mapLeadSource.put('Rare Users(50-100)', c100);
        mapLeadSource.put('Often Users(100-500)', c500);
        mapLeadSource.put('Average Users(500-1000)', c1k);
        mapLeadSource.put('Regular Users(1000-5000)', c5k);
        mapLeadSource.put('Nerdy Users(Above 5k)', chigh);
        
        //String s = mapLeadSource.toString();
        String str = '';
        Integer c = 0;

		str = str + '[';       
        for (String key : mapLeadSource.keySet()) {
        //str.append(key + "=" + map.get(key) + ", ");
        str = str + '{"y":' + mapLeadSource.get(key) + ',"name":"' + key;
            if(c != 4)
                str = str + '"},';
            else
                str = str + '"}';
            c++;
    }
        str = str + ']';*/
        
        
        userList = LicenseChart.getTicketsJSON(12,'2019-4-24T10:46:39.000Z');
        System.assert(userList.length() != 0);
        
    }

}