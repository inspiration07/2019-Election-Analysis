use Election_Project1;

--Cleaning data

update tbl_AllCandidatesIndia
set party=trim(Party)

update tbl_WomenCandidatesIndia
set Party=trim(Party)

update tbl_WinnersIndia
set Party=trim(Party)


--Querying top 10 richest parties based on candidates total assets 

select top(10) Party,
sum(Total_Assets)as Richest_Parties 
from tbl_AllCandidatesIndia
group by Party
order by Richest_Parties DESC


--Top 10 candidates with the higest liabilities

select top(10) Candidate,Party,
max(Liabilities)as Top_10_Candidates_With_Liabilities
from tbl_AllCandidatesIndia
group by Candidate,Party
order by Top_10_Candidates_With_Liabilities DESC


/*Percentage of women contesting in 
the elections among the top 5 winning parties*/

create nonclustered index IX_tblAllCandidatesIndia 
on tbl_AllCandidatesIndia(Constituency,Candidate)

select A.Party,
convert(decimal(6,3),count(B.Candidate)*100.0/sum(count(*))
over(Partition BY A.Party)) AS PecentageOfWomenInEachParty
from tbl_AllCandidatesIndia AS A
LEFT JOIN tbl_WomenCandidatesIndia AS B ON
A.Candidate=B.Candidate and A.Constituency=B.Constituency
where A.Party='BJP' or A.Party='INC' 
or A.Party='DMK' or A.Party='AITC' 
or A.Party='YSRCP'
group by A.Party
order by PecentageOfWomenInEachParty DESC  


--Average number of criminal cases among the top 5 winning parties

select distinct Party,
avg(convert(decimal(6,3),Criminal_Case))
over(partition by Party) as AverageCriminalCasesPerParty
from tbl_WinnersIndia
where Criminal_Case>0 and Party='BJP' 
or Criminal_Case>0 and Party='INC' or 
Criminal_Case>0 and Party='AITC'
or Criminal_Case>0 and  Party='YSRCP'
or Criminal_Case>0 and  Party='DMK'
order by Party


/*Percentage of crorepatis(assets worth more than 10 million)
in the top 5 winning parties*/

with Per_Crorepatisall(Party,Total_Assets,Result1)as
(select Party,Total_Assets,
convert(numeric(10,5),count(Total_Assets)
over(partition by Party))as Result1
from tbl_AllCandidatesIndia),
Per_Crorepatissome(Party,Total_Assets,Result) as
(select Party,Total_Assets,
convert(numeric(10,5),count(Total_Assets)
over(partition by Party)) as Result
from tbl_AllCandidatesIndia
where Total_Assets>10000000)

select distinct A.Party,
convert(numeric(10,5),B.Result/A.Result1)*100 as Percent_Crorepatis 
from Per_Crorepatisall as A
right join Per_Crorepatissome as B 
on A.Party=B.Party and A.Total_Assets=B.Total_Assets
where A.Party='BJP' or A.Party='INC' 
or A.Party='DMK' or A.Party='YSRCP' or A.Party='AITC'
order by Percent_Crorepatis Desc


/*Analysing if the education of the winner of 
each constituecy matters or not with respect to graduation*/

select * into #tbl_WinnersEdu from tbl_WinnersIndia
select * into #tbl_AllCandidatesEdu from tbl_AllCandidatesIndia

alter table #tbl_WinnersEdu
add Result char(10) NULL
alter table #tbl_AllCandidatesEdu
add Result char(10) NULL;

With Party_Data AS (select top(100)percent Candidate,Constituency,
Party,Criminal_Case,Education,Total_Assets,
Liabilities,isnull(Result,'Lost')as Result 
from #tbl_AllCandidatesEdu
where Education='Graduate' 
or Education='Post Graduate'   
or Education='Graduate Professional'
or Education='Doctorate' 
AND Result!= 'Won'
UNION 
select top(100) percent Candidate,Constituency,
Party,Criminal_Case,Education,
Total_Assets,Liabilities,
isnull(Result,'Won')AS Result
from #tbl_WinnersEdu)
select Candidate,Constituency,
Party,Criminal_Case,Education,Total_Assets,
Liabilities,Result,
case when Education=  '8th Pass' and Result='Won' then  'Education does not matter'
     when Education= 'Illiterate' and Result='Won' then  'Education does not matter'
     when Education='10th Pass' and Result='Won' then  'Education does not matter'
     when Education='5th Pass' and Result='Won' then  'Education does not matter'
	 when Education='12th Pass' and Result='Won' then  'Education does not matter'
	 when Education='Literate' and Result='Won' then  'Education does not matter'
	 when Education='Not Given'and Result='Won'  then  'Education does not matter'
	 when Education='Others'  and Result='Won' then  'Education does not matter'
	 else 'NULL' END as Education_Analysis
from Party_Data 
order by Constituency,Result DESC


/*Splitting states based on majority seats 
won by BJP or other Parties*/

with PartyData1 (State,Party,Party_Classification)as
(select  State,Party
,case when Party<>'BJP' 
then 1 
else 2 
end as Party_Classification 
from tbl_WinnersIndia)
,
PartyData2(State,Party_Classification ,No_of_seats)as
(select distinct State,Party_Classification 
,count(Party)
over(partition by Party_Classification ,State) 
as No_of_seats from PartyData1)
,
PartyData3(State,Party_Classification,No_of_seats,Rank_seats)
as(select State,Party_Classification,No_of_seats,
DENSE_RANK()over(partition by State order by No_of_seats desc)
as Rank_seats
from PartyData2)

select distinct State,No_of_seats,
case when Party_Classification=1 
then 'Majority seats not won by BJP' 
else 'Majority seats won by BJP' 
end as StatesWonandNotWonByBJP
from PartyData3
where Rank_seats=1


/*Inserting data of each constituency's coordinates 
as a point to represent data as spatial results*/

create table #tbl_Geo
(Coordinates geography not null,Constituency varchar(100) not null)

insert into #tbl_Geo values(geography::STGeomFromText('Point(76.3388484 9.4980667)',4326),'ALAPPUZHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.3980464 14.2250932)',4326),'CHITRADURGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.7336521 11.4916043)',4326),'NILGIRIS')
insert into #tbl_Geo values(geography::STGeomFromText('Point(90.9820668 26.3215985)',4326),'BARPETA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.1894876 22.1926884)',4326),'DIAMOND HARBOUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.972681 24.8430682)',4326),'MALDAHA DAKSHIN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.2801785 24.1759039)',4326),'MUHIDABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.0167423 20.1342042)',4326),'KANDHAMAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.986456 14.4425987)',4326),'NELLorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.268411 24.0982607)',4326),'BAHARAMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.8136569 8.6982226)',4326),'ATTINGAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.5783078 25.5877901)',4326),'GHAZIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(90.1932043578654 25.5282975734654)',4326),'TURA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1510421 29.1637099)',4326),'NAINITAL-UDHAMSINGH NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.7962492 27.9064649)',4326),'KHERI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.9842256 25.242453)',4326),'BHAGALPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.390982 26.1196607)',4326),'MUZAFFARPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.403086 32.0413917)',4326),'GURDASPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.646666 29.5892407)',4326),'ALMorA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.1859495 26.0739138)',4326),'AZAMGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.5976672 27.5705152)',4326),'BAHRAICH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.39703 30.6435345)',4326),'FATEHGARH SAHIB')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.6369415 23.2156354)',4326),'GANDHINAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.3775524 18.8249767)',4326),'SHIRUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6868815 14.7937065)',4326),'UTTARA KANNADA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.4976741 15.8496953)',4326),'BELGAUM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.7885163 23.1764665)',4326),'UJJAIN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.0746957 12.2252841)',4326),'TIRUVANNAMALAI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5933645 24.4676805)',4326),'KODARMA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.5878546 16.4291905)',4326),'CHIKKODI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.7870414 9.2647582)',4326),'PATHANAMTHITTA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4288534 20.4969108)',4326),'KENDRAPARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.5322481 17.4503375)',4326),'MALKAJGIRI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.5650394155806 25.1363077637419)',4326),'MIRZAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.5684594 25.4484257)',4326),'JHANSI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5213092 31.6861745)',4326),'HAMIRPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.8245398 20.2960587)',4326),'BHUBANESWAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.7909507 22.8765026)',4326),'ARAMBAG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.2774207 23.0797595)',4326),'KHUNTI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.3119159 28.0229348)',4326),'BIKANER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.3883455 22.7674278)',4326),'BARRACKPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.712479 24.585445)',4326),'UDAIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9147268 27.8753399)',4326),'SHAHJAHANPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.1409152 22.0796545)',4326),'BILASPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.606611 28.8955152)',4326),'ROHTAK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8776559 19.0759837)',4326),'MUMBAI SOUTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.486671 17.385044)',4326),'HYDERABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.5299541 27.4292761)',4326),'MISRIKH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.0711661 26.3482938)',4326),'MADHUBANI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.2767327 19.4968732)',4326),'GADCHIROLI CHIMUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.9777482 25.5647103)',4326),'BUXAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.6918921 23.671195)',4326),'BOLPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.5443287 26.1156595)',4326),'GHOSI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.6050959 17.6795276)',4326),'ZAHIRABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7315344 13.4354985)',4326),'CHIKKBALLAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.568101 13.9299299)',4326),'SHIMOGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9452748 12.9624975)',4326),'SRIPERUMBUDUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.9660638 23.6888636)',4326),'ASANSOL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(89.9743463 26.0206982)',4326),'DHUBRI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.9073688 27.4265731)',4326),'VALMIKI NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.1302716 16.1808917)',4326),'MACHILIPATNAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.4191795 13.6287557)',4326),'TIRUPATI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1288412 18.4385553)',4326),'KARIMNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.372493 22.5759112)',4326),'KOLKATA UTTAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.5320107 19.6640624)',4326),'ADILABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.1649001 19.9137363)',4326),'KALAHANDI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.3955506 18.1066576)',4326),'VIZIANAGARAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.3340589 10.3070105)',4326),'CHALAKUDY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6399163 26.4498954)',4326),'AJMER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.8420716 30.2457963)',4326),'SANGRUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5199079 17.9103939)',4326),'BIDAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.3296565 26.1458649)',4326),'JALAUN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.0754657 22.8457457)',4326),'DINDorI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.8829895 20.462521)',4326),'CUTTACK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.8367282 20.3792965)',4326),'YAVATMAL WASHIM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.8498292 28.406963)',4326),'BULANDSHAHR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.4129729 25.6873691)',4326),'MACHHLISHAHR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.018261 17.6804639)',4326),'SATARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.2028754 22.8045665)',4326),'JAMSHEDPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4187308 22.0086978)',4326),'MAYURBHANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.5473014 27.2514781)',4326),'KAISERGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.7216527 29.1491875)',4326),'HISAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.9375739 23.164543)',4326),'MIZorAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5434572 24.8866859)',4326),'NAWADA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.9853322 25.2132649)',4326),'JAHANABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6229699 24.8829177)',4326),'CHITTorGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.2996368 24.19135)',4326),'GIRIDIH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.7940911 19.3149618)',4326),'BERHAMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5816847 21.628933)',4326),'KEONJHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.6846658 22.750651)',4326),'KHEDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(69.8597406 23.7337326)',4326),'KACHCHH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.3179347451651 22.5996481970163)',4326),'DHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.0142866 24.9538803)',4326),'SASARAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.3209555 19.1382514)',4326),'NANDED')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1673575 11.2188958)',4326),'NAMAKKAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.0031455 16.5774798)',4326),'AMALAPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.224718 24.9195147)',4326),'JAMUI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4701416 25.50452)',4326),'KHAGARIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.3943282 22.1202674)',4326),'MATHURAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(70.4579436 21.5222203)',4326),'JUNAGADH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.095962 21.1124067)',4326),'MAHASAMUND')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.9927652 27.307462)',4326),'JAIPUR RURAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.123996 15.11766)',4326),'SOUTH GOA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.6077865 13.2846993)',4326),'BANGALorE RURAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.9288242 12.8464805)',4326),'VELLorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5945627 12.9715987)',4326),'BANGALorE NorTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.1210274 23.8500156)',4326),'PATAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.8816345 19.8346659)',4326),'JALNA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.5940544 17.9689008)',4326),'WARANGAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.2755486 13.0823077)',4326),'CHENNAI CENTRAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9527836 9.8583987)',4326),'IDUKKI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.1319057 25.6328682)',4326),'RAIGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.7468071 22.6636967)',4326),'GHATAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.9534815 19.1071317)',4326),'BASTAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.0169135 20.1808672)',4326),'DADRA AND NAGAR HAVELI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.1416132 25.1256823)',4326),'JALorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.123996 16.9429263)',4326),'HATKANANGLE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.2961468 19.9615398)',4326),'CHANDRAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.316109 8.959352)',4326),'TENKASI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.9927652 28.5923723)',4326),'BHIWANI MAHENDRAGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0940867 18.6725047)',4326),'NIZAMABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1604971 28.2699017)',4326),'AONLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.9188533 22.2858078)',4326),'TAMLUK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.6045134 26.1233718)',4326),'SUPAUL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.3198819 22.4256613)',4326),'MEDINIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.7946387 25.9239677)',4326),'MADHEPURA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.8860034 25.0583257)',4326),'RAJSAMAND')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1582143 12.1210997)',4326),'DHARMAPURI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(93.8655303 24.7121881)',4326),'INNER MANIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.027659 26.7829103)',4326),'ETAWAH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0372792 15.8281257)',4326),'KURNOOL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.43655 26.4831584)',4326),'GOPALGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.3957331 27.1591961)',4326),'FIROZABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.1838293 21.812876)',4326),'BALAGHAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.1416173 32.9159847)',4326),'UDHAMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.4789351 22.7247556)',4326),'BARASAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.2707184 13.0826802)',4326),'CHENNAI NorTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.264538 25.2604696)',4326),'CHANDAULI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.6077865 28.338333)',4326),'GAUTAM BUDDHA NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.9450379 26.0982167)',4326),'KISHANGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.7733286 28.8386481)',4326),'MorADABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.3542049 27.1543104)',4326),'PASCHIM CHAMPARAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.227607 28.9427827)',4326),'BAGHPAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.5717631 28.5903614)',4326),'SAMBHAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.1305395 19.2403305)',4326),'KALYAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.5914616 23.041727)',4326),'AHMEDABAD WEST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.8342957 17.329731)',4326),'GULBARGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.2149575 12.5265661)',4326),'KRISHNAGIRI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.0023634 17.6896435)',4326),'ANAKAPALLE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.1519304 21.7644725)',4326),'BHAVNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.138541 17.3123703)',4326),'CHEVELLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9342451 20.5992349)',4326),'VALSAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.0087746 13.2544335)',4326),'TIRUVALLUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.5591073 25.5540648)',4326),'KATIHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.8960201 21.9011601)',4326),'BETUL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5488232 24.5805983)',4326),'JHALAWAR BARAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.9259013 10.7677201)',4326),'PONNANI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.3713855 22.5979218)',4326),'MANDLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.7972825 34.0836708)',4326),'SRINAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.8075272 28.62494)',4326),'PILIBHIT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.921758 14.4644085)',4326),'DAVANAGERE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.117325 13.3378762)',4326),'TUMKUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.6615029 16.1691096)',4326),'BAGALKOT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8633635 19.1411973)',4326),'MUMBAI NorTH WEST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.0243094 26.2389469)',4326),'JODHPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.6149893 21.8335244)',4326),'KHARGONE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.8986502 24.5339177)',4326),'SATNA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7171642 11.3410364)',4326),'ERODE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.4982741 17.4399295)',4326),'SECUNDERABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(93.092296 26.534442)',4326),'KALIABor')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.2956273 28.6279559)',4326),'EAST DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.9638899 11.7383735)',4326),'KALLAKURICHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.769885 19.6967136)',4326),'PALGHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4996546 22.4866756)',4326),'SINGHBHUM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.9200515059821 24.8874480018968)',4326),'BANKA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.1271542 25.4181638)',4326),'BEGUSARAI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.8567437 18.5204303)',4326),'PUNE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.4326837906194 29.4435198534023)',4326),'NAGINA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7566523 8.7139126)',4326),'TIRUNELVELI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.8775218 18.3273486)',4326),'ARAKU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.3949632 21.8974003)',4326),'RAIGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8633635 19.1411973)',4326),'MUMBAI NorTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.8918454 26.1542045)',4326),'DARBHANGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.4752757 21.9705529)',4326),'JANJGIR CHAMPA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.0366677 23.3315103)',4326),'RATLAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.8722642 31.6339793)',4326),'AMRITSAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5552066 29.9680035)',4326),'SAHARANPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.0685134 28.7186211)',4326),'NorTH WEST DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.7493272 27.1983368)',4326),'NAGAUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.7629893 26.8139844)',4326),'BASTI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.230337 28.6505331)',4326),'CHANDNI CHOWK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.9454745 30.210994)',4326),'BATHINDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.1487007 33.7311255)',4326),'ANANTNAG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.123996 21.7468548)',4326),'NANDURBAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.673673 27.4924134)',4326),'MATHURA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.7898023 19.9974533)',4326),'NASHIK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.2998842 9.9816358)',4326),'ERNAKULAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.3568619 23.300232)',4326),'SHAHDOL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(93.5749064370918 26.1937147224477)',4326),'AUTONOMOUS DISTRICT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.3433139 19.8761653)',4326),'AURANGABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.5122178 27.5329718)',4326),'SIKKIM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.774776 19.2608384)',4326),'PARBHANI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.5605732 23.1744548)',4326),'RANAGHAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.6525739 27.20781)',4326),'DOMARIYAGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.1250479 27.3965071)',4326),'HARDOI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.30397793829 24.536425600525)',4326),'REWA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.5621737 27.1446035)',4326),'MAHARAJGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8310607 21.1702401)',4326),'SURAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.0990746 31.4235965)',4326),'KHADOor SAHIB')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.332411 26.8996953)',4326),'DAUSA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.2606185 22.8344992)',4326),'DAHOD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.4365402 16.3066525)',4326),'GUNTUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.3636758 23.9924669)',4326),'HAZARIBAGH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.7195567 26.5214579)',4326),'JALPAIGURI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.710031 16.8301708)',4326),'BIJAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(89.5319627 26.4922164)',4326),'ALIPURDUA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0766036 10.9600778)',4326),'KARUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.043175 22.1240025)',4326),'SUNDARGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.8570259 32.7266016)',4326),'JAMMU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.3616405 23.3322026)',4326),'PURULIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.7500595 22.3594501)',4326),'KorBA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.004759 10.6608925)',4326),'POLLACHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.3703662 11.8744775)',4326),'KANNUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.5919758 11.601558)',4326),'VADAKARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8394819 9.3639356)',4326),'RAMANATHAPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(71.2203555 21.6015242)',4326),'AMRELI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(71.3966865 25.7521467)',4326),'BARMER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.3405772 22.7505213)',4326),'SREERAMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.346786 26.5490299)',4326),'BANSGAON')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.4349761 23.5461394)',4326),'BANSWARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1348361 8.7641661)',4326),'THOOTHUKKUDI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.6552401 11.6839585)',4326),'NAAPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.0482912 19.2812547)',4326),'BHIWANDI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.1567298 15.3504652)',4326),'KOPPAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.4808775 9.8432999)',4326),'SIVAGANGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.9880191 26.6854584)',4326),'MOHANLALGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5154705167717 25.2108057440725)',4326),'NALANDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.3962535 26.1689087)',4326),'SIWAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.0036199 17.602625)',4326),'MAHABUBABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.088374 25.5510396)',4326),'PHULPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.0335820535889 21.2404821795977)',4326),'RAVER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.2461183 25.1785773)',4326),'MALDAHA UTTAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.1047287 24.4589833)',4326),'JANGIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(93.4195527 27.5077359)',4326),'ARUNACHAL WEST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.7794179 30.7333148)',4326),'CHANDIGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.9618979 27.1339874)',4326),'GONDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.2691006 32.0998031)',4326),'KANGRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5314817 9.2384874)',4326),'MAVELIKKARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8802139 17.507769)',4326),'BHONGIR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.261853 18.0529357)',4326),'MEDAK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.3591531 24.8649128)',4326),'KARIMGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.3177894 28.4089123)',4326),'FARIDABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.3152442205133 9.2344395)',4326),'GUNA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.327146878065 21.3925831961317)',4326),'RAMTEK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.6586401 11.7400867)',4326),'ANDAMAN AND NICOBAR ISLANDS')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.9974385 22.4549909)',4326),'JHARGRAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(70.8021599 22.3038945)',4326),'RAJKOT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.0710967 11.0509762)',4326),'MALAPPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.467318 28.9051778)',4326),'AMROHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5213092 31.6861745)',4326),'HAMIRPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5009298 13.8222599)',4326),'HINDUPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.1457934 26.7729751)',4326),'FAIZABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.0496499 16.2359181)',4326),'NARASARAOPET')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.3898552 22.9011588)',4326),'HOOGHLY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(93.2583626 24.2993576)',4326),'OUTER MANIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.2184815 17.6868159)',4326),'VISAKHAPATNAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.78041 11.2587531)',4326),'KOZHIKODE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.049922 15.5057232)',4326),'ONGOLE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.2851541 25.1803303)',4326),'KARAKAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.6345735 27.5529907)',4326),'ALWAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.0534454 22.9675929)',4326),'DEWAS')
insert into #tbl_Geo values(geography::STGeomFromText('Point(71.6369542 22.7251204)',4326),'SURENDRANAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5981223 20.6504753)',4326),'DHENKANAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.5021152 23.4013101)',4326),'KRISHNANAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.5660852 30.3011858)',4326),'TEHRI GARHWAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.314212 22.5038174)',4326),'KOLKATA DAKSHIN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1350904 29.3731673)',4326),'BIJNor')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.0659858 26.2585371)',4326),'SULTANPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.9624435 9.5680116)',4326),'VIRUDHUNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5012734 31.2355318)',4326),'ANANDPUR SAHIB')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4962996 21.0573616)',4326),'BHADRAK')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0035172 16.7488379)',4326),'MAHBUBNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9342451 19.1249534)',4326),'MUMBAI NorTH EAST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.2864879 26.5071484)',4326),'KARAULI DHOLPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.2580268 28.7183693)',4326),'NorTH EAST DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9958748 21.7051358)',4326),'BHARUCH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.8040345 17.0005383)',4326),'RAJAHMUNDRY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.2090212 28.6139391)',4326),'NEW DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.3709008 22.4954988)',4326),'JADAVPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9299127183942 22.5650357352787)',4326),'ANAND')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.3499496 34.1990498)',4326),'BARAMULLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.0220287 28.798299)',4326),'RAMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.7583351 30.6769462)',4326),'FARIDKOT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.7846336 10.3280265)',4326),'LAKSHADWEEP')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.0754657 20.1990123)',4326),'KANKER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.5840195 27.3825853)',4326),'FARRUKHABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.0251659 27.2281937)',4326),'MAINPURI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1003289 13.217176)',4326),'CHITTOor')
insert into #tbl_Geo values(geography::STGeomFromText('Point(90.266699 26.4014362)',4326),'KOKRAJHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.9381729 22.057437)',4326),'CHHINDWARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.2684169 17.0574663)',4326),'NALGONDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.2479061 12.8437814)',4326),'DAKSHINA KANNADA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.1514447 17.2472528)',4326),'KHAMMAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.3497612 21.8314037)',4326),'KHANDWA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.4022233 28.1317038)',4326),'JHUNJHUNU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.9739144 25.3176452)',4326),'VARANASI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.9927274402859 26.4959609379434)',4326),'MorENA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7523039 20.9319821)',4326),'AMRAVATI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.878282 29.9695121)',4326),'KURUKSHETRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.8799805 29.9093759)',4326),'GANGANAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.2135177 24.8255215)',4326),'GODDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.9811665 21.4668716)',4326),'SAMBALPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.0881546 21.1458004)',4326),'NAGPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.9664886 25.4532672)',4326),'UJIARPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.8572047 22.6590646)',4326),'BASIRHAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.8623960463291 25.2153257078211)',4326),'KOTA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.0419642 18.185332)',4326),'OSMANABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9558321 11.0168445)',4326),'COIMBATorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5980174 12.8915077)',4326),'BANGALorE CENTRAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.5583436272239 25.7794858951368)',4326),'PALI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.4701972 9.9329832)',4326),'THENI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1554591 14.1969204)',4326),'RAJAMPET')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8806852 11.2342104)',4326),'PERAMBALUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.0683519 24.6850005)',4326),'ROBERTSGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1378274 10.7869994)',4326),'THANJAVUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.7925592 26.6528495)',4326),'TEZPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.5621737 27.1446035)',4326),'MAHARAJGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(71.7622481 24.3454739)',4326),'BANASKANTHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.1122499 21.1255374)',4326),'BARDOLI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1221587788093 11.6500279101425)',4326),'SALEM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.067959 28.6663433)',4326),'WEST DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.208324 25.6924354)',4326),'HAJIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4303859 23.7956531)',4326),'DHANBAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.7570024 23.2216974)',4326),'AHMEDABAD EAST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8327991 20.3973736)',4326),'DAMAN AND DIU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9520348 20.9467019)',4326),'NAVSARI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.1493722 19.7173703)',4326),'HINGOLI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.8312359 19.8134554)',4326),'PURI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.487285 15.4776876)',4326),'NANDYAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.8633635 19.0722214)',4326),'MUMBAI NorTH CENTRAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(70.05773 22.4707019)',4326),'JAMNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.3102489 16.4939417)',4326),'NAGARKURNOOL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.7787163 27.9462395)',4326),'LAKHIMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.2002745 29.3939892)',4326),'KAIRANA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.4528067 26.1324689)',4326),'ARARIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.4396622 25.0622533)',4326),'NAWGONG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.4386591 23.8323022)',4326),'DAMOH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.1003894 13.0033234)',4326),'HASSAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.007808 15.4589236)',4326),'DHARWAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.6590579541471 19.6142702416525)',4326),'ASKA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.2636394 22.5957689)',4326),'HOWRAH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.9134794 21.4933578)',4326),'BALASorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.1841701 20.5292147)',4326),'BULDHANA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.6393805 12.2958104)',4326),'MYSorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(91.4048249 23.899682)',4326),'TRIPURA WEST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.1370148 26.5883988)',4326),'JAYNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.0361376 26.7671755)',4326),'SANT KABIR NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.6141396 8.8932118)',4326),'KOLLAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.3868797 30.3397809)',4326),'PATIALA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.7531324 18.990088)',4326),'BEED')
insert into #tbl_Geo values(geography::STGeomFromText('Point(91.7362365 26.1445169)',4326),'GAUHATI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.6664797 25.5541358)',4326),'ARRAH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.3387687610139 25.4768246001153)',4326),'BANDA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.8567932 26.6098139)',4326),'PURVI CHAMPARAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.1319953 11.6853575)',4326),'WAYANAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.9707262 28.2925364)',4326),'CHURU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9106202 19.0307289)',4326),'MUMBAI SOUTH CENTRAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.3565608 16.216018)',4326),'RAICHUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9770821887026 19.2151754403362)',4326),'THANE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.1706221 20.2548998)',4326),'JAGATSINGHPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.7375604193909 23.8397722695387)',4326),'SAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.7789054 24.8332708)',4326),'SILCHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7064137 28.9844618)',4326),'MEERUT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.6789519 27.5680156)',4326),'SITAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.8567932 25.8559698)',4326),'SARAN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.4735600307152 25.3712657328422)',4326),'MUNGER')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.6679292 27.0945291)',4326),'FATEHPUR SIKRI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.9869276 12.4995966)',4326),'KASARAGOD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.946166 26.8466937)',4326),'LUCKNOW')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.2662745 27.0410218)',4326),'DARJEELING')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.6654148 27.5625106)',4326),'ETAH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0492265 27.5980718)',4326),'HATHRAS')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9864071 23.181467)',4326),'JABALPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.792959007653 26.9176475634281)',4326),'JAIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.1375645 25.5940947)',4326),'PATALIPUTRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.9534815 27.5977504)',4326),'SHRAWASTI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9441794741298 31.7288522949115)',4326),'MANDI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.2942313 26.5145872)',4326),'SHEOHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.8139718 23.5235719)',4326),'VIDISHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.6525686 11.1017705)',4326),'MAYILADUTHURAI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.7791283 26.5024286)',4326),'DEorIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.7868233 25.8560271)',4326),'SAMASTIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.6021946 20.745319)',4326),'WARDHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.1872857 28.4816551)',4326),'SOUTH DELHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.5676981 25.3804531)',4326),'BHADOHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.0150735 28.9930823)',4326),'SONIPAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.5469898 19.2281434)',4326),'NABARANGPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1642478 29.9456906)',4326),'HARIDWAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(69.6293059 21.6416979)',4326),'PorBANDAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(94.9119621 27.4728327)',4326),'DIBRUGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.8938018 18.2949165)',4326),'SRIKAKULAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.2769166 26.26197)',4326),'JHANJHARPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5458462 10.6453971)',4326),'ALATHUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.1812187 22.3071588)',4326),'VADODARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5029996 27.2151863)',4326),'BHARATPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.5169466271609 18.0350183359908)',4326),'MADHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.0266383 28.4594965)',4326),'GURGAON')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7288655 22.7518961)',4326),'HOSHANGABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.6330166 22.7770479)',4326),'PANCHMAHAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.9932969 23.8476704)',4326),'SABARKANTHA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.0119993 22.3084941)',4326),'CHHOTA UDAIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.782122 30.3752011)',4326),'AMBALA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.2298706 25.5960176)',4326),'PATNA SAHIB')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.4861449 11.9401378)',4326),'VILUPPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.9241376 26.293939)',4326),'SALEMPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.3731675 26.7605545)',4326),'GorAKHPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.8572758 30.900965)',4326),'LUDHIANA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(91.9881527 23.9408482)',4326),'TRIPURA EAST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.0354406 27.3565321)',4326),'DHAURAHRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.1649001 22.9494079)',4326),'SURGUJA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.846311 25.4358011)',4326),'ALLAHABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.6915429 26.4683952)',4326),'AMBEDKAR NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.7787021 24.2071092)',4326),'SIDHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.7278803 24.0078819)',4326),'RAJGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.6704128 13.0840593)',4326),'ARAKKONAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1281350956482 13.1372606158722)',4326),'KOLAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.4762124 19.7645364)',4326),'SHIRDI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.7996035 25.9209503)',4326),'FATEHPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.412615 23.2599333)',4326),'BHOPAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.0897934 22.4763526)',4326),'ULUBERIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.7860916 26.5637768)',4326),'BHIND')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.9800561 25.9149697)',4326),'PRATAPGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.9705292 26.1650564)',4326),'LALGANJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.1271229 28.0311101)',4326),'BADAUN')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9904825 29.6856929)',4326),'KARNAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.2432527 16.7049873)',4326),'KOLHAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.309562 23.3440997)',4326),'RANCHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.0099025703786 20.7000030417546)',4326),'AKOLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.5814773 16.8523973)',4326),'SANGLI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.7085091 29.4726817)',4326),'MUZAFFARNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.5761829 31.3260152)',4326),'JALANDHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.4752551 25.7771391)',4326),'PURNIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.4304381 28.3670355)',4326),'BAREILLY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.0337501 21.0972123)',4326),'RAJNANDGAON')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.7123327 18.813487)',4326),'KorAPUT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(86.3326058 20.8341019)',4326),'JAJPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.6186379 23.8401675)',4326),'BIRBHUM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0880129 27.8973944)',4326),'ALIGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.3318736 26.449923)',4326),'KANPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.0080745 27.1766701)',4326),'AGRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.3214681 23.067179)',4326),'BISHNUPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.6946586 12.818456)',4326),'KANCHEEPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.8448512 10.7672313)',4326),'NAGAPATTINAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.8577258 22.7195687)',4326),'INDorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.8291109 23.0467269)',4326),'BANGAON')
insert into #tbl_Geo values(geography::STGeomFromText('Point(72.3693252 23.5879607)',4326),'MAHESANA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9366376 8.5241391)',4326),'THIRUVANANTHAPURAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.4344727 13.3936652)',4326),'UDUPI CHIKMAGALUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(92.0322172 26.44632)',4326),'MANGALDOI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.9063906 17.6599188)',4326),'SOLAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.9830029 15.5163112)',4326),'NorTH GOA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.4471973243561 18.758331212224)',4326),'MAVAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.6837033 25.7464145)',4326),'JAUNPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.7517427 21.778109)',4326),'KANTHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.814238 26.1540538)',4326),'AMETHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.4846069 20.7011108)',4326),'BOLANGIR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.911483 31.5143178)',4326),'HOSHIARPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.2528139 26.2144806)',4326),'RAE BARELI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.4102464652945 22.6418840832391)',4326),'DUM DUM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(89.4482079 26.3452397)',4326),'COOCH BEHAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.0952431 16.7106604)',4326),'ELURU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.6480153 16.5061743)',4326),'VIJAYAWADA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.3410656 11.1085242)',4326),'TIRUPPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.0783875 23.2312686)',4326),'BANKURA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6313183 25.3407388)',4326),'BHILWARA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.7748979 20.9042201)',4326),'DHULE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9136731 27.0514156)',4326),'KANNAUJ')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.6845216 23.4409325)',4326),'LOHARDAGA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5603828 18.4087934)',4326),'LATUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.0679018 24.0734356)',4326),'MANDSOUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.7479789 19.0948287)',4326),'AHMEDNAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.7830612 25.2372834)',4326),'BALURGHAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6224755 30.9331348)',4326),'FIROZPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.9927652 26.1996181)',4326),'TONK SAWAI MADHOPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.8951488 12.5218157)',4326),'MANDYA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.2707184 13.0826802)',4326),'CHENNAI SOUTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.1397935 27.6093912)',4326),'SIKAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9192702 20.9847143)',4326),'BHANDARA GONDIYA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.5012971 26.5886976)',4326),'SITAMARHI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(88.050979 23.1321751)',4326),'BARDHAMAN PURBA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.871802 24.2065446)',4326),'CHATRA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.6296413 21.2513844)',4326),'RAIPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.2488088 24.2684794)',4326),'DUMKA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.0348695798572 29.5431029018924)',4326),'SIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(74.6077971 18.1791791)',4326),'BARAMATI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.3119227 23.5204443)',4326),'BARDHAMAN DURGAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.4671375 15.9039445)',4326),'BAPATLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.1734033 31.1048145)',4326),'SHIMLA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.6320212 21.3470154)',4326),'BARGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.3433139 19.8761653)',4326),'AURANGABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(80.4878195 26.5393449)',4326),'UNNAO')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.2144349 10.5276416)',4326),'THRISSUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.7713687 11.7480419)',4326),'CUDDALorE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.6005911 14.6818877)',4326),'ANANTAPUR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(95.8987139 28.3590669)',4326),'ARUNACHAL EAST')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.0946926 18.7357931)',4326),'RAIGAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.4158129 17.0711874)',4326),'BANGALorE SOUTH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.6912455 11.4070449)',4326),'CHIDAMBARAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.7046725 10.7904833)',4326),'TIRUCHIRAPPALLI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5221531 9.5915668)',4326),'KOTTAYAM')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8382644 29.8687682)',4326),'GARHWAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(94.5624426 26.1584354)',4326),'NAGALAND')
insert into #tbl_Geo values(geography::STGeomFromText('Point(94.2036696 26.7509207)',4326),'JorHAT')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5619419 34.2268475)',4326),'LADAKH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.3990674 14.7950698)',4326),'HAVERI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(75.5626039 21.0076578)',4326),'JALGAON')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.1833809 26.9268042)',4326),'BARABANKI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.5488232 10.9512736)',4326),'PALAKKAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9437312 11.9261471)',4326),'CHAMARAJANAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.8083133 11.9415915)',4326),'PUDUCHERRY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(82.2474648 16.9890648)',4326),'KAKINADA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.5384507 8.0883064)',4326),'KANNIYAKUMARI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.354965 25.6838206)',4326),'VAISHALI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.9694579 10.3623794)',4326),'DINDIGUL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1197754 9.9252007)',4326),'MADURAI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.6938559553682 14.200329725584)',4326),'PEDDAPALLE')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.2849169 21.1904494)',4326),'DURG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(85.0002336 24.7913957)',4326),'GAYA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(83.8869698 26.7398787)',4326),'KUSHI NAGAR')
insert into #tbl_Geo values(geography::STGeomFromText('Point(87.8311825426161 25.0541225608109)',4326),'RAJMAHAL')
insert into #tbl_Geo values(geography::STGeomFromText('Point(77.4537578 28.6691565)',4326),'GHAZIABAD')
insert into #tbl_Geo values(geography::STGeomFromText('Point(73.5594128 16.7144944)',4326),'RATNAGIRI SINDHUDURG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(91.8932535 25.5787726)',4326),'SHILLONG')
insert into #tbl_Geo values(geography::STGeomFromText('Point(81.4031707 25.361054)',4326),'KAUSHAMBI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8320779 24.7456147)',4326),'TIKAMGARH')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.1857115 25.8307174)',4326),'BALLIA')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.9198549 24.8318452)',4326),'KHAJURAHO')
insert into #tbl_Geo values(geography::STGeomFromText('Point(84.1857115 24.1286106)',4326),'PALAMU')
insert into #tbl_Geo values(geography::STGeomFromText('Point(79.2838024621784 12.6687276907178)',4326),'ARANI')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.1828308 26.2182871)',4326),'GWALIor')
insert into #tbl_Geo values(geography::STGeomFromText('Point(76.9214428 15.1393932)',4326),'BELLARY')
insert into #tbl_Geo values(geography::STGeomFromText('Point(78.8242089 14.4673154)',4326),'KADAPA')


--Analysing data based on spatial results
select W.Candidate,W.State,W.Constituency,W.Party,W.Criminal_Case,
W.Education,W.Total_Assets,W.Liabilities,G.Coordinates
from tbl_WinnersIndia as W
left join #tbl_Geo as G
on W.Constituency=G.Constituency


