/*
    TODO:Invocable Apex can be layered for sepratation of concern , to make query layer , call out layer , dml layer etc.FFLIB UOW can be also implemented
*/
public class SendOrderInfo {
  @InvocableMethod(label='Order Callout' description='Send the OrderInfo' category= 'Order')
  public static void sendOrders(List<ID> ids) {
    List<OrderInfo> orderList=new List<OrderInfo>();
    for (Order eachOrder:[Select Id,OrderNumber, BillToContact.Email from Order where id in:ids]) {
          orderList.add(new OrderInfo(eachOrder.Id,eachOrder.OrderNumber,eachOrder.BillToContact.Email));
    }
    // enequeuing the queuebale job
    System.enqueueJob(new ExecuteQueuableBatches(orderList, 30));
  }
  
}