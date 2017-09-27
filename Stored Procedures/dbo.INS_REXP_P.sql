SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_REXP_P]
	@X XML
AS
BEGIN
	DECLARE @Rqid BIGINT;
   
   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');

   UPDATE Payment_Detail
      SET PAY_STAT = '002'   
    WHERE PYMT_RQST_RQID = @Rqid;
    
    SET @X = '<Process><Request rqid="" msttcode="" ssttcode=""/></Process>';
    SET @X.modify(
      'replace value of (//Request/@rqid)[1]
       with sql:variable("@Rqid")'
    );
    
    SET @X.modify(
      'replace value of (//Request/@msttcode)[1]
       with 3'
    );
    
    SET @X.modify(
      'replace value of (//Request/@ssttcode)[1]
       with 1'
    );
    EXEC dbo.NEXT_LEVL_F @X;
END
GO
