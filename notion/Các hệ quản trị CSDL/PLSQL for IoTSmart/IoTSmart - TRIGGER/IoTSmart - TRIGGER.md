# IoTSmart - TRIGGER

## 1. Prevent Negative Stock (Safety Net)

```SQL
CREATE OR REPLACE TRIGGER trg_no_negative_stock
BEFORE UPDATE ON stock
FOR EACH ROW
BEGIN
    IF :NEW.quantity_on_hand < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Stock cannot be negative');
    END IF;
END;
/
```

## 2. Lock Issued Invoice

```SQL
CREATE OR REPLACE TRIGGER trg_lock_issued_invoice
BEFORE UPDATE ON invoice
FOR EACH ROW
BEGIN
    IF :OLD.invoice_status = 'ISSUED' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Issued invoice cannot be modified');
    END IF;
END;
/
```

