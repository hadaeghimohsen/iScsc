SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- User Defined Function

CREATE FUNCTION [dbo].[GET_H2BI_U](@Hex VARCHAR(16)) --Convert hex to bigint
RETURNS BIGINT -- e.g. select dbo.fn_Hex2BigInt('7ff2a5')

AS 
BEGIN
   DECLARE 
       @i INT, 
       @len INT, 
       @c CHAR(1), 
       @result BIGINT
       
   SELECT @Hex=UPPER(@Hex)
   SELECT 
       @len=LEN(@Hex), 
       @i=@len, 
       @result=    CASE 
                       WHEN @len>0 THEN 0
                   END
                   
   WHILE (@i>0)
   BEGIN
       SELECT 
           @c=SUBSTRING(@Hex,@i,1), 
           @result=@result
               +(ASCII(@c)
               -(  CASE 
                       WHEN @c BETWEEN 'A' AND 'F' THEN 55 
                       ELSE    CASE 
                                   WHEN @c BETWEEN '0' AND '9' THEN 48 
                               END
                   END
                ))  * POWER(16.,@len-@i),
           @i=@i-1
   END -- while

   RETURN @result
END -- function

GO
