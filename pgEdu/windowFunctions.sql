Window Funtions
----------------------

CREATE TABLE posts (
  id integer PRIMARY KEY,
  body varchar,
  created_at timestamp DEFAULT current_timestamp
);

CREATE TABLE comments (
 id INTEGER PRIMARY KEY,
 post_id integer NOT NULL,
 body varchar,
 created_at timestamp DEFAULT current_timestamp
);

/* make two posts */
INSERT INTO posts VALUES (1, 'foo');
INSERT INTO posts VALUES (2, 'bar');

/* make 4 comments for the first post */
INSERT INTO comments VALUES (1, 1, 'foo old');
INSERT INTO comments VALUES (2, 1, 'foo new');
INSERT INTO comments VALUES (3, 1, 'foo newer');
INSERT INTO comments VALUES (4, 1, 'foo newest');

/* make 4 comments for the second post */
INSERT INTO comments VALUES (5, 2, 'bar old');
INSERT INTO comments VALUES (6, 2, 'bar new');
INSERT INTO comments VALUES (7, 2, 'bar newer');
INSERT INTO comments VALUES (8, 2, 'bar newest');


-- Normal Query 

SELECT posts.id AS post_id, comments.id AS comment_ids, comments.body AS body
FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id;


-- Window Query

SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body,
  dense_rank() OVER (
    PARTITION BY post_id
    ORDER BY comments.created_at DESC
  ) AS comment_rank
FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id;


SELECT comment_id, post_id, body FROM (
  SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body,
    dense_rank() OVER (
      PARTITION BY post_id
      ORDER BY comments.created_at DESC
    ) AS comment_rank
  FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id
) AS ranked_comments
WHERE comment_rank < 4;

--CTE 


WITH ranked_comments AS (
  SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body,
    dense_rank() OVER (
      PARTITION BY post_id
      ORDER BY comments.created_at DESC
    ) AS comment_rank
  FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id
)

SELECT
  post_id,
  comment_id,
  body
FROM ranked_comments
WHERE comment_rank < 4;

---
----  Function	Return Type	Description
----  row_number()	bigint	number of the current row within its partition, counting from 1
----  rank()	bigint	rank of the current row with gaps; same as row_number of its first peer
----  dense_rank()	bigint	rank of the current row without gaps; this function counts peer groups
----  percent_rank()	double precision	relative rank of the current row: (rank - 1) / (total partition rows - 1)
----  cume_dist()	double precision	cumulative distribution: (number of partition rows preceding or peer with current row) / total partition rows
----  ntile(num_buckets integer)	integer	integer ranging from 1 to the argument value, dividing the partition as equally as possible
----  lag(value anyelement [, offset integer [, default anyelement ]])	same type as value	returns value evaluated at the row that is offset rows before the current row within the partition; if there is no such row, instead return default (which must be of the same type as value). Both offset and default are evaluated with respect to the current row. If omitted, offset defaults to 1 and default to null
----  lead(value anyelement [, offset integer [, default anyelement ]])	same type as value	returns value evaluated at the row that is offset rows after the current row within the partition; if there is no such row, instead return default (which must be of the same type as value). Both offset and default are evaluated with respect to the current row. If omitted, offset defaults to 1 and default to null
----  first_value(value any)	same type as value	returns value evaluated at the row that is the first row of the window frame
----  last_value(value any)	same type as value	returns value evaluated at the row that is the last row of the window frame
----  nth_value(value any, nth integer)	same type as value	returns value evaluated at the row that is the nth row of the window frame (counting from 1); null if no such row

-- SECOND EXAMPLE

CREATE TABLE product_groups (
	group_id serial PRIMARY KEY,
	group_name VARCHAR (255) NOT NULL
);

CREATE TABLE products (
	product_id serial PRIMARY KEY,
	product_name VARCHAR (255) NOT NULL,
	price DECIMAL (11, 2),
	group_id INT NOT NULL,
	FOREIGN KEY (group_id) REFERENCES product_groups (group_id)
);
---Second, insert some rows into these tables:

INSERT INTO product_groups ( group_name )
VALUES	('Smartphone'),	('Laptop'),	('Tablet');

INSERT INTO products (product_name, group_id,price)
VALUES  ('Microsoft Lumia', 1, 200),
	('HTC One', 1, 400),
	('Nexus', 1, 500),
	('iPhone', 1, 900),
	('HP Elite', 2, 1200),
	('Lenovo Thinkpad', 2, 700),
	('Sony VAIO', 2, 700),
	('Dell Vostro', 2, 800),
	('iPad', 3, 700),
	('Kindle Fire', 3, 150),
	('Samsung Galaxy Tab', 3, 200);
	
---------------	
SELECT
	group_name,
	AVG (price)
FROM
	products
INNER JOIN product_groups USING (group_id)
GROUP BY  group_name;

----------AVG

SELECT
	product_name,
	price,
	group_name,
	AVG (price) OVER (
	   PARTITION BY group_name
	)
FROM
	products
	INNER JOIN 
		product_groups USING (group_id);
	
--------------ROW_NUMBER
SELECT
	product_name,
	group_name,
	price,
	ROW_NUMBER () OVER (
		PARTITION BY group_name
		ORDER BY
			price
	)
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------RANK
SELECT
	product_name,
	group_name,
  price,
	RANK () OVER (
		PARTITION BY group_name
		ORDER BY
			price
	)
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------DENSE_RANK
SELECT
	product_name,
	group_name,
	price,
	DENSE_RANK () OVER (
		PARTITION BY group_name
		ORDER BY
			price
	)
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------FIRST_VALUE
SELECT
	product_name,
	group_name,
	price,
	FIRST_VALUE (price) OVER (
		PARTITION BY group_name
		ORDER BY
			price
	) AS lowest_price_per_group
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------LAST_VALUE
SELECT
	product_name,
	group_name,
	price,
	LAST_VALUE (price) OVER (
		PARTITION BY group_name
		ORDER BY
			price RANGE BETWEEN UNBOUNDED PRECEDING
		AND UNBOUNDED FOLLOWING
	) AS highest_price_per_group
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------LAG
SELECT
	product_name,
	group_name,
	price,
	LAG (price, 1) OVER (
		PARTITION BY group_name
		ORDER BY
			price
	) AS prev_price,
	price - LAG (price, 1) OVER (
		PARTITION BY group_name
		ORDER BY
			price
	) AS cur_prev_diff
FROM
	products
INNER JOIN product_groups USING (group_id);

---------------LEAD
SELECT
	product_name,
	group_name,
	price,
	LEAD (price, 1) OVER (
		PARTITION BY group_name
		ORDER BY
			price
	) AS next_price,
	price - LEAD (price, 1) OVER (
		PARTITION BY group_name
		ORDER BY
			price
	) AS cur_next_diff
FROM
	products
INNER JOIN product_groups USING (group_id);





