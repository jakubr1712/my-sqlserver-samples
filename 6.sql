----- 1 -----

select 
    orderid,
    customerid,
    orderdate,
    row_number() over (partition by customerid order by orderdate asc) as numer_zamowienia_klienta
from orders;


----- 2 -----

select 
    productid,
    productname,
    unitprice,
    ntile(4) over (order by unitprice) as segment_cenowy
from products;


----- 3 -----

select 
    orderid,
    customerid,
    orderdate,
    lag(orderdate) over (partition by customerid order by orderdate) as poprzednia_data
from orders;

----- 4 -----


select 
    o.customerid,
    sum(od.unitprice * od.quantity) over (partition by o.customerid) as wartosc_zamowien,
    o.orderid
from [order details] od
join orders o on o.orderid = od.orderid;



----- 5 -----

select 
    productid,
    sum(quantity) over (partition by productid) as laczna_ilosc,
    orderid
from [order details];


----- 6 -----


select 
    customerid,
    orderid,
    orderdate,
    min(orderdate) over (partition by customerid) as najwczesniejsze_zamowienie
from orders;
