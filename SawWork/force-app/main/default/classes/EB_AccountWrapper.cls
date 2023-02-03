public class EB_AccountWrapper
    {
        public Account acc{get; set;}
        public Boolean selected {get; set;}
        public EB_AccountWrapper(Account a)
        {
            acc = a;
            selected = false;
        }
    }