obj-$(CONFIG_QCOM_TSENS)	+= qcom_tsens.o
qcom_tsens-y			+= tsens.o tsens-common.o tsens-8916.o tsens-8974.o tsens-8960.o tsens-8996.o
obj-$(CONFIG_MSM_BCL_PERIPHERAL_CTL) += bcl_peripheral.o
obj-y += msm_lmh_dcvs.o

ifdef CONFIG_DEBUG_KERNEL
obj-$(CONFIG_QTI_THERMAL_LIMITS_DCVS) += lmh_dbg.o
endif

obj-$(CONFIG_QTI_VIRTUAL_SENSOR) += qti_virtual_sensor.o
obj-$(CONFIG_QTI_AOP_REG_COOLING_DEVICE) += regulator_aop_cdev.o
obj-$(CONFIG_REGULATOR_COOLING_DEVICE) += regulator_cdev.o
obj-$(CONFIG_QTI_QMI_COOLING_DEVICE) += thermal_mitigation_device_service_v01.o qmi_cooling.o
obj-$(CONFIG_QTI_BCL_PMIC5) += bcl_pmic5.o
obj-$(CONFIG_QTI_BCL_SOC_DRIVER) += bcl_soc.o
