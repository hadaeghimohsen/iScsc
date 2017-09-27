SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Expense_Detail]
AS
SELECT RQTP.CODE AS RQTP_CODE, RQTP.RQTP_DESC, RQTP.MUST_LOCK AS RQTP_MUST_LOCK, RQTT.RQTT_DESC, 
    RQTT.CODE AS RQTT_CODE, RQRQ.SUB_SYS AS RQRQ_SUB_SYS, RQRQ.CODE AS RQRQ_CODE, 
    RQRQ.PERM_STAT AS RQRQ_PERM_STAT, EPIT.EPIT_DESC, EPIT.TYPE AS EPIT_TYPE, EXTP.EXTP_DESC, 
    EXTP.CODE AS EXTP_CODE, CASH.CODE AS CASH_CODE, CASH.NAME AS CASH_NAME, 
    CASH.BANK_BRNC_CODE AS CASH_BANK_BRNC_CODE, CASH.BANK_NAME AS CASH_BANK_NAME, 
    CASH.BANK_ACNT_NUMB AS CASH_BANK_ACNT_NUMB, CASH.TYPE AS CASH_TYPE, CASH.CASH_STAT, 
    EXCS.EXCS_STAT, REGN.CODE AS REGN_CODE, REGN.NAME AS REGN_NAME, 
    REGL_EXPN.YEAR AS REGL_EXPN_YEAR, REGL_EXPN.CODE AS REGL_EXPN_CODE, 
    REGL_EXPN.TYPE AS REGL_EXPN_TYPE, REGL_EXPN.REGL_STAT AS REGL_EXPN_STAT, 
    REGL_EXPN.TAX_PRCT AS REGL_TAX_PRCT, REGL_EXPN.DUTY_PRCT AS REGL_DUTY_PRCT, 
    EXPN.CODE AS EXPN_CODE, EXPN.EXPN_DESC, EXPN.PRIC AS EXPN_PRIC, EXPN.EXTR_PRCT AS EXPN_EXTR_PRCT, 
    EXPN.EXPN_STAT, CTGY.NAME AS CTGY_NAME, CTGY.CTGY_DESC, CTGY.CODE AS CTGY_CODE, 
    MTOD.CODE AS MTOD_CODE, MTOD.MTOD_DESC, FIGH.FILE_NO, REGL_ACNT.TYPE AS REGL_ACNT_TYPE, 
    REGL_ACNT.REGL_STAT AS REGL_ACNT_STAT, EXPN.ADD_QUTS, EXPN.COVR_DSCT, EXPN.EXPN_TYPE, 
    EXPN.BUY_PRIC, EXPN.BUY_EXTR_PRCT, EXPN.NUMB_OF_STOK, EXPN.NUMB_OF_SALE, 
    EXPN.NUMB_OF_REMN_DNRM
FROM dbo.Request_Requester AS RQRQ INNER JOIN
    dbo.Request_Type AS RQTP ON RQRQ.RQTP_CODE = RQTP.CODE INNER JOIN
    dbo.Requester_Type AS RQTT ON RQRQ.RQTT_CODE = RQTT.CODE INNER JOIN
    dbo.Expense_Type AS EXTP ON RQRQ.CODE = EXTP.RQRQ_CODE INNER JOIN
    dbo.Expense_Cash AS EXCS ON EXTP.CODE = EXCS.EXTP_CODE INNER JOIN
    dbo.Cash AS CASH ON EXCS.CASH_CODE = CASH.CODE INNER JOIN
    dbo.Regulation AS REGL_EXPN ON RQRQ.REGL_YEAR = REGL_EXPN.YEAR AND 
    RQRQ.REGL_CODE = REGL_EXPN.CODE INNER JOIN
    dbo.Expense AS EXPN ON EXTP.CODE = EXPN.EXTP_CODE AND REGL_EXPN.YEAR = EXPN.REGL_YEAR AND 
    REGL_EXPN.CODE = EXPN.REGL_CODE INNER JOIN
    dbo.Category_Belt AS CTGY ON EXPN.CTGY_CODE = CTGY.CODE INNER JOIN
    dbo.Method AS MTOD ON EXPN.MTOD_CODE = MTOD.CODE AND CTGY.MTOD_CODE = MTOD.CODE INNER JOIN
    dbo.Region AS REGN ON EXCS.REGN_PRVN_CNTY_CODE = REGN.PRVN_CNTY_CODE AND 
    EXCS.REGN_PRVN_CODE = REGN.PRVN_CODE AND EXCS.REGN_CODE = REGN.CODE INNER JOIN
    dbo.Fighter AS FIGH ON REGN.PRVN_CNTY_CODE = FIGH.REGN_PRVN_CNTY_CODE AND 
    REGN.PRVN_CODE = FIGH.REGN_PRVN_CODE AND REGN.CODE = FIGH.REGN_CODE AND 
    CTGY.CODE = FIGH.CTGY_CODE_DNRM AND MTOD.CODE = FIGH.MTOD_CODE_DNRM INNER JOIN
    dbo.Expense_Item AS EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
    dbo.Regulation AS REGL_ACNT ON EXCS.REGL_YEAR = REGL_ACNT.YEAR AND 
    EXCS.REGL_CODE = REGL_ACNT.CODE
WHERE (RQRQ.PERM_STAT = '002') AND (CASH.CASH_STAT = '002') AND (EXCS.EXCS_STAT = '002') AND 
    (REGL_EXPN.REGL_STAT = '002') AND (EXPN.EXPN_STAT = '002') AND (REGL_EXPN.TYPE = '001') AND 
    (REGL_ACNT.TYPE = '002') AND (REGL_ACNT.REGL_STAT = '002')
GO
EXEC sp_addextendedproperty N'MS_Description', N'', 'SCHEMA', N'dbo', 'VIEW', N'V#Expense_Detail', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[76] 4[8] 2[7] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[43] 4[23] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1[56] 3) )"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1[51] 4) )"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4[60] 2) )"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4) )"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 12
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -864
         Left = -5
      End
      Begin Tables = 
         Begin Table = "RQRQ"
            Begin Extent = 
               Top = 251
               Left = 298
               Bottom = 474
               Right = 496
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "RQTP"
            Begin Extent = 
               Top = 63
               Left = 527
               Bottom = 242
               Right = 717
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "RQTT"
            Begin Extent = 
               Top = 25
               Left = 77
               Bottom = 187
               Right = 269
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "EXTP"
            Begin Extent = 
               Top = 512
               Left = 613
               Bottom = 706
               Right = 773
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "EXCS"
            Begin Extent = 
               Top = 571
               Left = 277
               Bottom = 815
               Right = 498
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CASH"
            Begin Extent = 
               Top = 290
               Left = 65
               Bottom = 514
               Right = 247
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "REGL_EXPN"
            Begin Extent = 
               Top = 251
               Left = 818
               Bottom = 553
               Right = 978
            End
            DisplayFlags = 280
           ', 'SCHEMA', N'dbo', 'VIEW', N'V#Expense_Detail', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N' TopColumn = 0
         End
         Begin Table = "EXPN"
            Begin Extent = 
               Top = 527
               Left = 1290
               Bottom = 795
               Right = 1450
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CTGY"
            Begin Extent = 
               Top = 981
               Left = 1092
               Bottom = 1194
               Right = 1261
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "MTOD"
            Begin Extent = 
               Top = 1383
               Left = 1481
               Bottom = 1547
               Right = 1641
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "REGN"
            Begin Extent = 
               Top = 978
               Left = 65
               Bottom = 1172
               Right = 246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "FIGH"
            Begin Extent = 
               Top = 978
               Left = 429
               Bottom = 1521
               Right = 643
            End
            DisplayFlags = 280
            TopColumn = 7
         End
         Begin Table = "EPIT"
            Begin Extent = 
               Top = 664
               Left = 803
               Bottom = 842
               Right = 981
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "REGL_ACNT"
            Begin Extent = 
               Top = 616
               Left = 15
               Bottom = 915
               Right = 175
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
      PaneHidden = 
   End
   Begin DataPane = 
      PaneHidden = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 42
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1650
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 5715
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      PaneHidden = 
      Begin ColumnWidths = 11
         Column = 1620
         Alias = 2115
         Table = 2280
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#Expense_Detail', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Expense_Detail', NULL, NULL
GO
