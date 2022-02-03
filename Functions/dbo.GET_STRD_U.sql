SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_STRD_U]
(
	@X XML
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @Type VARCHAR(3),
	        @Rqid BIGINT,
	        @RsltDesc NVARCHAR(MAX);
	
	SELECT @Type = @x.query('//Request').value('(Request/@type)[1]', 'VARCHAR(3)');
	
	IF @Type = '001' -- برای نمایش اطلاعات و مشخصات خریدار در درآمد متفرقه
	BEGIN
	   SELECT @Rqid = @x.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
	   SELECT 
	      @RsltDesc = 
         (
            SELECT CASE f.FGPB_TYPE_DNRM
                        WHEN '005' THEN 
                           N'نام مشتری : ' + ISNULL(fp.FRST_NAME, N'مهمان') + N' ' + ISNULL(fp.LAST_NAME, N'آزاد') + N' - ' + CHAR(10) +
                           N'شماره تلفن همراه : ' + ISNULL(fp.CELL_PHON, N'No Mobile')
                        ELSE 
                           N'نام مشتری : ' + F.NAME_DNRM + CHAR(10) +
                           N'شماره تلفن همراه : ' + ISNULL(f.CELL_PHON_DNRM, N'No Mobile')
                   END 
              FROM dbo.Request_Row rr, dbo.Fighter f LEFT OUTER JOIN dbo.Fighter_Public fp ON f.FILE_NO = fp.FIGH_FILE_NO AND fp.RQRO_RQST_RQID = @Rqid AND fp.RECT_CODE = '001'
             WHERE rr.RQST_RQID = @Rqid
               AND rr.FIGH_FILE_NO = f.FILE_NO
         )
       FROM dbo.Request r
      WHERE r.RQID = @Rqid;
	END
	
	RETURN @RsltDesc; 
END
GO
