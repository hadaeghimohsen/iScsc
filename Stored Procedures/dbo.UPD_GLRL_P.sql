SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_GLRL_P]
	-- Add the parameters for the stored procedure here
	@RqroRqstRqid BIGINT,
	@RqroRwno SMALLINT,
	@FighFileNo BIGINT,
	@ConfStat VARCHAR(3),
	@ChngType VARCHAR(3),
	@DebtType VARCHAR(3),
	@Amnt INT,
	@AgreDate DATETIME,
	@PaidDate DATETIME,
	@ChngResn VARCHAR(3),
	@ResnDesc NVARCHAR(250),
	@Glid BIGINT
AS
BEGIN
	UPDATE dbo.Gain_Loss_Rial
	   SET CONF_STAT = @ConfStat
	      ,CHNG_TYPE = @ChngType
	      ,DEBT_TYPE = @DebtType
	      ,AMNT      = @Amnt
	      ,AGRE_DATE = @AgreDate
	      ,PAID_DATE = @PaidDate
	      ,CHNG_RESN = @ChngResn
	      ,RESN_DESC = @ResnDesc
    WHERE RQRO_RQST_RQID = @RqroRqstRqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FighFileNo;    
END
GO
