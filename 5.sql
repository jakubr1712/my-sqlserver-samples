
create table productsjson (
    productid int primary key,
    jsondata nvarchar(max)
);

------- 1  concat + json_query --------
truncate table productsjson;

insert into productsjson (productid, jsondata)
select 
    p.productid,
    (
        select 
            p.productid,
            p.productname,
            p.supplierid,
            p.categoryid,
            p.unitprice
        for json path, without_array_wrapper
    ) as jsondata
from products as p;

select * from productsjson;



------- 1  for json path --------

truncate table productsjson;

insert into productsjson (productid, jsondata)
select 
    p.productid,
    (
        select 
            productid,
            productname,
            supplierid,
            categoryid,
            unitprice
        from products as p2
        where p2.productid = p.productid
        for json path, without_array_wrapper
    ) as jsondata
from products as p;

select * from productsjson;



------- 2 ---------


update productsjson
set jsondata = json_modify(jsondata, '$.unitprice',
    cast(cast(json_value(jsondata, '$.unitprice') as decimal(10,2)) * 1.10 as varchar))
where 
    json_value(jsondata, '$.supplierid') in (
        select supplierid from suppliers where country = 'usa'
    );

select * from productsjson;




----- 3 --------
update productsjson
set jsondata = json_modify(jsondata, '$.orders',
    '[' + isnull((
        select string_agg(cast(orderid as nvarchar), ',')
        from [order details]
        where productid = productsjson.productid
    ), '') + ']'
);

select * from productsjson;
