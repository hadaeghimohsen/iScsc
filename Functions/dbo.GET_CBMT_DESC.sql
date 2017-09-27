SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_CBMT_DESC]
(
	@CbmtCode BIGINT
)
RETURNS NVARCHAR(250)
AS
BEGIN
	DECLARE @CbmtDesc NVARCHAR(250);
	--SELECT @CbmtCode = @X.query('Club_Method').value('(Club_Method/@code)[1]', 'BIGINT');
	
	SELECT @CbmtDesc = M.MTOD_DESC + N' ، ' + S.DOMN_DESC + '  ' + F.NAME_DNRM + ' ' + N'از ساعت ' + CAST(C.STRT_TIME AS VARCHAR(5)) + N' تا ' + CAST(C.END_TIME AS VARCHAR(5)) + ' ' + N' روزهای ' + D.DOMN_DESC
	  FROM Fighter F, Club_Method C, Method M, D$SXDC S, D$DYTP D
	 WHERE F.FILE_NO = C.COCH_FILE_NO
	   AND M.CODE = C.MTOD_CODE
	   AND F.SEX_TYPE_DNRM = S.VALU
	   AND C.DAY_TYPE = D.VALU
	   AND C.CODE = @CbmtCode;
   RETURN @CbmtDesc;
END
GO
