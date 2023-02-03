public class EdnsResponse
{
        public String token;
        public Zone zone;
        
        public class Zone
        {
            public String name; 
            
            public Soa soa;
            public List<Ns> ns = new List<Ns>();
            public List<A> a = new List<A>();
            public List<Cname> cname = new List<Cname>(); 
            
            public Zone(){
                
            }
            
            public Zone(String name,Soa soa,List<Ns> ns,List<A> a,List<Cname> cname)
            {
                this.name = name;
                this.soa = soa;
                this.ns.addAll(ns);
                this.a.addAll(a);
                this.cname.addAll(cname);
            }          
        }
        
        public class Soa
        {
            public long minimum;
            public long ttl;
            public long serial;
            public long expire;
            public long refresh;
            public long retry;
            public string originserver;
            public string contact;
        }
        
        public class Ns
        {
            public string target;
            public string name;
            public boolean active;
            public long ttl;
        }
        
        public class A
        {
            public string target;
            public string name;
            public boolean active;
            public long ttl;
        }
        
        public class Cname
        {
            public string target;
            public string name;
            public boolean active;
            public long ttl;
        }
    }