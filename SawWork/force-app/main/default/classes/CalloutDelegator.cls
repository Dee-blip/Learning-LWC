public class CalloutDelegator
{
    private string requestLabel;
    private Promise logger;
    public static HttpResponse execute(HttpRequest hReq)
    {
        Http http= new Http();
        HttpResponse hResponse = http.send(hReq);
        //if(!Test.isRunningTest()) new Promise(new CalloutLog(hReq, hResponse)).execute();
        new Promise(new CalloutLog(hReq, hResponse)).error(new PromiseErrorDebugger()).execute();
        return hResponse;
    }

    public Continuation executeAsync(HttpRequest hReq)
    {
        Continuation con = new Continuation(60);
        con.continuationMethod = 'processResponse';
        logger = new Promise(new CalloutLog(hReq));
        this.requestLabel = con.addHttpRequest(hReq);
        return con;
    }

    public HttpResponse fetchResponse()
    {
        HttpResponse hResponse = Continuation.getResponse(this.requestLabel);
        if(!Test.isRunningTest()) logger.then(new CalloutLog(hResponse)).error(new PromiseErrorDebugger()).execute();
        //logger.then(new CalloutLog(hResponse)).execute();
        return hResponse;
    }

}