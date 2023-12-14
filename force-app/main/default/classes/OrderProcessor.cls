public class OrderProcessor implements Queueable, Database.AllowsCallouts{
  
public List<OrderInfo> orderInfos;

public OrderProcessor(List<OrderInfo> orderInfos){
    this.orderInfos = orderInfos;
}
  
public void execute(QueueableContext context) {     
    try {               
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:OrderNPS/orders');
        req.setMethod('POST');
        req.setBody(JSON.serialize(orderInfos));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('----------->'+res.getBody());             
    } catch( System.Exception e) {
        System.debug('@@@-->'+e);     
    }         

}
}