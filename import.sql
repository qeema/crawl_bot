CREATE DATABASE IF NOT EXISTS crawl;
USE crawl;
CREATE TABLE IF NOT EXISTS crawl.museums (
  id smallint primary key,
  name varchar(255),
  url varchar(255),
  start_date datetime,
  end_date datetime,
  sleep varchar(255),
  pref_id smallint,
  address varchar(255),
  del_flg boolean default false,
  created_at datetime,
  updated_at datetime
);
