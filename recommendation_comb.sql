DELIMITER \\
create procedure RecommendationCombin(in usr varchar(70), in author varchar(70),in publisher varchar(70))
begin
drop table if exists Rec_Result;
drop table if exists input_rfs;
drop table if exists temp_usr_recom;
create table input_rfs(
usr_n varchar(32) primary key,
min_r int,
max_r int
);
insert into input_rfs(
select Username as usr_n,min(Rating) as min_r,max(Rating) as max_r from Ratings group by Username
);
	-- call the recommendFromSimilar funciton
create table temp_usr_recom(
ISBN varchar(10) primary key,
Title int,
author varchar(255),
PublishName varchar(8192),
Score int
);
call RecommendFromSimilar(input_rfs.usr_n,input_rfs.min_r,input_rfs.max_r,@ISBN_usr,@Title_usr,@Author_usr, @PublisherName_usr, @Score_usr);
insert ignore into temp_usr_recom values (@ISBN_usr,@Title_usr,@Author_usr, @PublisherName_usr, @Score_usr);
	-- call the RecommendFromFriends funciton
call RecommendFromFriends(input_rfs.usr_n,input_rfs.min_r,@ISBN_frien,@Title_frien,@Author_frien, @PublisherName_frien, @Score_frien);
insert ignore into temp_usr_recom values (@ISBN_frien,@Title_frien,@Author_frien, @PublisherName_frien, @Score_frien);
	-- call the RecommendFromAuthor funciton
call RecommendFromAuthor(input_rfs.usr_n,input_rfs.min_r,@ISBN_auth,@Title_auth,@Author_auth, @PublisherName_auth, @Score_auth);
insert ignore into temp_usr_recom values (@ISBN_auth,@Title_auth,@Author_auth, @PublisherName_auth, @Score_auth);

	-- call the RecommendFromPublisher funciton
call RecommendFromPublisher(input_rfs.usr_n,input_rfs.min_r,@ISBN_pub,@Title_pub,@Author_pub, @PublisherName_pub, @Score_pub);
insert ignore into temp_usr_recom values (@ISBN_auth,@Title_auth,@Author_auth, @PublisherName_auth, @Score_auth);

end
delimiter ;
