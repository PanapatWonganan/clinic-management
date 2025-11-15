// Global variables
let currentCustomerId = null;
let provinces = [];
let districts = [];
let subDistricts = [];

// Thai Address API functions
async function loadProvinces() {
    try {
        const response = await fetch('/test/address/provinces');
        const data = await response.json();
        if (data.success) {
            provinces = data.data;
            populateProvinceSelect();
        }
    } catch (error) {
        console.error('Error loading provinces:', error);
    }
}

function populateProvinceSelect() {
    const select = document.getElementById('customerProvinceId');
    select.innerHTML = '<option value="">เลือกจังหวัด</option>';
    provinces.forEach(province => {
        select.innerHTML += `<option value="${province.id}">${province.name_th}</option>`;
    });
}

async function loadDistricts(provinceId) {
    try {
        const response = await fetch(`/test/address/districts/${provinceId}`);
        const data = await response.json();
        if (data.success) {
            districts = data.data;
            populateDistrictSelect();
        }
    } catch (error) {
        console.error('Error loading districts:', error);
        districts = [];
        populateDistrictSelect();
    }
}

function populateDistrictSelect() {
    const select = document.getElementById('customerDistrictId');
    select.innerHTML = '<option value="">เลือกอำเภอ/เขต</option>';
    select.disabled = districts.length === 0;
    
    districts.forEach(district => {
        select.innerHTML += `<option value="${district.id}">${district.name_th}</option>`;
    });
}

async function loadSubDistricts(districtId) {
    try {
        const response = await fetch(`/test/address/sub-districts/${districtId}`);
        const data = await response.json();
        if (data.success) {
            subDistricts = data.data;
            populateSubDistrictSelect();
        }
    } catch (error) {
        console.error('Error loading sub-districts:', error);
        subDistricts = [];
        populateSubDistrictSelect();
    }
}

function populateSubDistrictSelect() {
    const select = document.getElementById('customerSubDistrictId');
    select.innerHTML = '<option value="">เลือกตำบล/แขวง</option>';
    select.disabled = subDistricts.length === 0;
    
    subDistricts.forEach(subDistrict => {
        select.innerHTML += `<option value="${subDistrict.id}">${subDistrict.name_th} (รหัส ${subDistrict.postal_code})</option>`;
    });
}

// Customer modal functions
function openCustomerModal() {
    const modal = document.getElementById('customerModal');
    const form = document.getElementById('customerForm');
    const title = document.getElementById('modalTitle');
    const saveBtn = document.getElementById('saveCustomerBtn');

    title.textContent = 'เพิ่มลูกค้าใหม่';
    saveBtn.innerHTML = '<i class="fas fa-save"></i> บันทึก';
    form.reset();
    document.getElementById('customerId').value = '';
    document.getElementById('customerPassword').required = true;
    currentCustomerId = null;

    modal.style.display = 'block';
}

async function editCustomer(id) {
    currentCustomerId = id;
    
    try {
        const response = await fetch(`/admin/customers/${id}`);
        const data = await response.json();
        
        if (data.success) {
            const customer = data.data;
            
            document.getElementById('customerId').value = customer.id;
            document.getElementById('customerName').value = customer.name || '';
            document.getElementById('customerEmail').value = customer.email || '';
            document.getElementById('customerPhone').value = customer.phone || '';
            document.getElementById('customerAddress').value = customer.address || '';
            
            // Set address dropdowns if available
            if (customer.province_id) {
                document.getElementById('customerProvinceId').value = customer.province_id;
                document.getElementById('customerProvince').value = customer.province || '';
                try {
                    await loadDistricts(customer.province_id);
                    if (customer.district_id) {
                        document.getElementById('customerDistrictId').value = customer.district_id;
                        document.getElementById('customerDistrict').value = customer.district || '';
                        await loadSubDistricts(customer.district_id);
                        if (customer.sub_district_id) {
                            document.getElementById('customerSubDistrictId').value = customer.sub_district_id;
                        }
                    }
                } catch (e) {
                    console.error('Error loading address data:', e);
                }
            }
            
            document.getElementById('customerPostalCode').value = customer.postal_code || '';
            document.getElementById('customerMembershipType').value = customer.membership_type || 'exMember';
            document.getElementById('customerPassword').required = false;

            document.getElementById('modalTitle').textContent = 'แก้ไขข้อมูลลูกค้า';
            document.getElementById('saveCustomerBtn').innerHTML = '<i class="fas fa-save"></i> อัปเดต';
            
            document.getElementById('customerModal').style.display = 'block';
        } else {
            alert('ไม่สามารถโหลดข้อมูลลูกค้าได้');
        }
    } catch (error) {
        console.error('Error:', error);
        alert('เกิดข้อผิดพลาด');
    }
}

function deleteCustomer(id) {
    if (confirm('คุณแน่ใจหรือไม่ที่จะลบลูกค้ารายนี้?')) {
        fetch(`/admin/customers/${id}`, {
            method: 'DELETE',
            headers: {
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                document.getElementById(`customer-row-${id}`).remove();
                alert('ลบลูกค้าเรียบร้อยแล้ว');
            } else {
                alert('ไม่สามารถลบลูกค้าได้: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('เกิดข้อผิดพลาด');
        });
    }
}

function openMembershipModal(id) {
    alert('ฟีเจอร์จัดการ Membership กำลังพัฒนา');
}

function closeCustomerModal() {
    document.getElementById('customerModal').style.display = 'none';
}

function searchCustomers() {
    const searchTerm = document.getElementById('searchCustomer').value.toLowerCase();
    const rows = document.querySelectorAll('tbody tr');
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    loadProvinces();

    // Address dropdown event listeners
    document.getElementById('customerProvinceId').addEventListener('change', function() {
        const provinceId = this.value;
        const provinceName = provinces.find(p => p.id == provinceId)?.name_th || '';
        document.getElementById('customerProvince').value = provinceName;
        
        // Reset dependent dropdowns
        document.getElementById('customerDistrictId').value = '';
        document.getElementById('customerSubDistrictId').value = '';
        document.getElementById('customerDistrict').value = '';
        document.getElementById('customerPostalCode').value = '';
        
        if (provinceId) {
            loadDistricts(provinceId);
        } else {
            districts = [];
            subDistricts = [];
            populateDistrictSelect();
            populateSubDistrictSelect();
        }
    });

    document.getElementById('customerDistrictId').addEventListener('change', function() {
        const districtId = this.value;
        const districtName = districts.find(d => d.id == districtId)?.name_th || '';
        document.getElementById('customerDistrict').value = districtName;
        
        // Reset dependent dropdown
        document.getElementById('customerSubDistrictId').value = '';
        document.getElementById('customerPostalCode').value = '';
        
        if (districtId) {
            loadSubDistricts(districtId);
        } else {
            subDistricts = [];
            populateSubDistrictSelect();
        }
    });

    document.getElementById('customerSubDistrictId').addEventListener('change', function() {
        const subDistrictId = this.value;
        const subDistrict = subDistricts.find(sd => sd.id == subDistrictId);
        if (subDistrict) {
            document.getElementById('customerPostalCode').value = subDistrict.postal_code;
        } else {
            document.getElementById('customerPostalCode').value = '';
        }
    });

    // Form submission
    document.getElementById('customerForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = new FormData(this);
        const customerId = formData.get('id');
        const isEdit = customerId && customerId.trim() !== '';
        
        const url = isEdit ? `/admin/customers/${customerId}` : '/admin/customers';
        const method = isEdit ? 'PUT' : 'POST';
        
        const data = {};
        for (let [key, value] of formData.entries()) {
            if (key !== 'id') {
                data[key] = value;
            }
        }
        
        fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                closeCustomerModal();
                alert(isEdit ? 'อัปเดตลูกค้าเรียบร้อยแล้ว' : 'เพิ่มลูกค้าเรียบร้อยแล้ว');
                window.location.reload();
            } else {
                let errorMessage = data.message;
                if (data.errors) {
                    errorMessage += '\n\nรายละเอียด:\n';
                    Object.keys(data.errors).forEach(field => {
                        errorMessage += `- ${data.errors[field].join(', ')}\n`;
                    });
                }
                alert(errorMessage);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('เกิดข้อผิดพลาด');
        });
    });

    // Close modal when clicking outside
    window.addEventListener('click', function(event) {
        const modal = document.getElementById('customerModal');
        if (event.target === modal) {
            closeCustomerModal();
        }
    });
});