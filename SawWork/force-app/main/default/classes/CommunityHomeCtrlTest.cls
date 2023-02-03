@istest(SeeAllData=true)
public class CommunityHomeCtrlTest {
	static testmethod void CommunityHomeTest()
    {
        CommunityHomeCtrl.fetchNewsEventsId('');
        PGN_PageInfo p = new PGN_PageInfo();
        List<Integer> nList = new List<Integer>();
        nList.add(1);
        p.currentPageNumber = 1;
        p.totalPages = 2;
        p.pageCounter = nList;
    }
}