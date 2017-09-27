SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_PIMG_U]
(
	@X XML
)
RETURNS VARBINARY(MAX)
AS
   /*
      <Fighter fileno="">
         <Image rcdcrcid="" rwno=""/>
      </Fighter>
   */
BEGIN
   DECLARE @FileNo BIGINT
          ,@RcdcRcid BIGINT
          ,@Rwno SMALLINT;
   
   SELECT @FileNo = @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT')
         ,@RcdcRcid = @X.query('Fighter/Image').value('(Image/@rcdcrcid)[1]', 'BIGINT')
         ,@Rwno = @X.query('Fighter/Image').value('(Image/@rwno)[1]', 'SMALLINT');
   
   IF @FileNo <> 0 
      SELECT @RcdcRcid = IMAG_RCDC_RCID_DNRM
            ,@Rwno = IMAG_RWNO_DNRM
        FROM Fighter
       WHERE FILE_NO = @FileNo;
   
   RETURN( SELECT 
                CAST(
                    CAST(N'' AS XML).value(
                        'xs:base64Binary(sql:column("IMAG"))'
                      , 'VARBINARY(MAX)'
                    ) 
                    AS VARBINARY(MAX)
                ) AS IMAG
            FROM [dbo].[Image_Document] 
           WHERE RCDC_RCID = @RcdcRcid AND RWNO = @Rwno);
END
GO
