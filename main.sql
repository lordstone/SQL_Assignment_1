-- CSCI585 hw2
-- By Chengxi Shi

-- Q1:
-- http://sqlfiddle.com/#!15/a10cd
-- The url is for the second way. Due to sqlfiddle site problem, I cannot upload test SQL for the second way code 
-- please use the second way for grading, thanks

-- the first way

-- note: inorder to perform a good check on roomNum, we need create extension btree_gist.
-- However, in sqlfidle it needs superuser to do it
-- therefore, for comprehensive sql
-- please refer to the follows

create extension btree_gist;

CREATE TABLE HotelStays
(roomNum INTEGER NOT NULL,
arrDate timestamp NOT NULL,
depDate timestamp NOT NULL,
guestName CHAR(30) NOT NULL,
CHECK (arrDate <= depDate),
EXCLUDE USING gist (roomNum with =,
	tsrange(arrDate, depDate) WITH &&),
PRIMARY KEY (roomNum, arrDate));

-- the second way
-- PLEASE USE THIS FOR GRADING

CREATE TABLE HotelStays
(roomNum INTEGER NOT NULL,
arrDate date NOT NULL,
depDate date NOT NULL,
guestName CHAR(30) NOT NULL,
CHECK (arrDate <= depDate),
PRIMARY KEY (roomNum, arrDate));

//
CREATE FUNCTION check_stay_update() RETURNS TRIGGER 
AS $check_stay_update$
BEGIN
if exists( select * from HotelStays) and
  exists (select * from HotelStays where 
    (NEW.roomNum = roomNum) and 
     (NEW.depDate < depDate and NEW.arrDate > arrDate)
      or
      (NEW.depDate > depDate and NEW.arrDate < arrDate)
      or
      (NEW.arrDate < arrDate and NEW.depDate > arrDate)
      or
      (arrDate < NEW.arrDate and depDate > NEW.arrDate)
     )
 then raise exception 'Overlapping time range.';
  return null;
 end if;
 return new;
END;
$check_stay_update$ LANGUAGE plpgsql;
//

//
CREATE TRIGGER check_update
    before INSERT or update ON HotelStays
    FOR EACH ROW
    EXECUTE PROCEDURE check_stay_update();
//
 
INSERT INTO HotelStays(roomNum, arrDate, depDate, guestName)
VALUES 
(123, to_date('20160202', 'YYYYMMDD'), to_date('20160206','YYYYMMDD'), 'A'),
(123, to_date('20160204', 'YYYYMMDD'), to_date('20160208','YYYYMMDD'), 'B'),
(201, to_date('20160210', 'YYYYMMDD'), to_date('20160206','YYYYMMDD'), 'C')
; 

select * from HotelStays;


-- Q2:
-- http://www.sqlfiddle.com/#!15/42051/1

CREATE TABLE Students 
  (SID INTEGER NOT NULL,
   ClassName CHAR(6) NOT NULL,
   Grade CHAR(1) NOT NULL,
   PRIMARY KEY (SID, ClassName));
 
 INSERT INTO Students(SID, ClassName, Grade)
 VALUES
 (123, 'ART123', 'A'),
 (123, 'BUS456', 'B'),
 (666, 'REL100', 'D'),
 (666, 'ECO966', 'A'),
 (666, 'BUS456', 'B'),
 (345, 'BUS456', 'A'),
 (345, 'ECO966', 'F');
 
 SELECT ClassName, 
 COUNT(ClassName) as Total 
 FROM Students
 GROUP BY ClassName
 ORDER BY Total;
 
 -- Q3
 -- http://sqlfiddle.com/#!9/e13e27/8
 
 create table Projects
(ProjectID char(4) NOT NULL,
 Step integer NOT NULL,
 Status char(1) NOT NULL,
 primary key (ProjectID, Step)
 );
 
 insert into Projects(ProjectID, Step, Status)
 values
   ('P100' , 0 , 'C'),
   ('P100' , 1 , 'W'),
   ('P100' , 2 , 'W'),
   ('P201' , 0 , 'C'),
   ('P201' , 1 , 'C'),
   ('P333' , 0 , 'W'),
   ('P333' , 1 , 'W'),
   ('P333' , 2 , 'W'),
   ('P333' , 3 , 'W');
   
select ProjectID 
from Projects
where Step = 0 and Status = 'C'
and (ProjectID
in 
    (select ProjectID 
    from Projects
    where Step = 1 and Status = 'W')
  or
  ProjectID in 
    (select ProjectID from 
     (select ProjectID, count(ProjectID) as total
      from Projects
      group by ProjectID) as tablex
     where total = 1)
);

  
  
-- Q4
-- http://sqlfiddle.com/#!15/0410a/1

create table Addresses
(Name varchar(30) not null,
 Address char(1) not null,
 ID integer not null,
 SameFam integer,
 primary key (ID, Name)
);

insert into Addresses(Name, Address, ID, SameFam)
values
('Alice', 'A', 10, NULL),
('Bob', 'B', 15, NULL),
('Carmen', 'C', 22, NULL),
('Diego', 'A', 9, 10),
('Ella', 'B', 3, 15),
('Farkhad', 'D', 11, NULL);

delete 
from Addresses
where ID in 
(select a.ID 
 from Addresses a 
 join
 Addresses b
 on a.ID = b.SameFam);
 
 select * from Addresses;



-- Q5 
 -- http://sqlfiddle.com/#!9/f25b3/2
 
 create table Menu
(Chef char(1) not null,
 Dish varchar(50) not null,
 primary key(Chef, Dish)
);
  
insert into Menu(Chef, Dish)
values
('A', 'Mint chocolate brownie'),
('B', 'Upside down pineapple cake'),
('B', 'Creme brulee'),
('B', 'Mint chocolate brownie'),
('C', 'Upside down pineapple cake'),
('C', 'Creme brulee'),
('D', 'Apple pie'),
('D', 'Upside down pineapple cake'),
('D', 'Creme brulee'),
('E', 'Apple pie'),
('E', 'Upside down pineapple cake'),
('E', 'Creme brulee'),
('E', 'Bananas Foster');

create table Dishes
(Dish varchar(50) not null,
primary key(Dish)
);

insert into Dishes(Dish)
values
('Apple pie'),
('Upside down pineapple cake'),
('Creme brulee');

select Chef
from 
	(select Chef, count(Chef) as total
	from
		(select Chef, Dish from Menu
		where Dish in (select Dish from Dishes))
	as a
	group by Chef)
as b
where total in (select count(Dish) from Dishes);

-- Q5 Bonus 1
-- no sqlfiddle because the server always respond with  "oops"

select Chef 
from (select Chef,
      count(Chef) as total from
      (select Chef from Menu join Dishes on menu.Dish = Dishes.Dish)
      as a
      group by Chef)
      as b
where total in (select count(Dish) from Dishes);

-- Q5 Bonus 2
-- no sqlfiddle because the server always respond with  "oops"

select Chef from Menu
where Dish in (select Dish from Dishes) group by Chef
having count(*) = (select count(*) from Dishes);

