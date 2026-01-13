// State
let uploadedFiles = []; // { name: string, content: string, df: object }
let mergedData = null; // { index: [], columns: [], data: {} }
let savedDiffRefCol = null; // Store saved diff reference column name
const targetOrder = [
    "pdk_ecc.txt",
    "2V0_r3_vdd_4500.txt",
    "2V0_r5_vdd_4500.txt",
    "3V0_r1_vdd_4500.txt",
    "4V0_r4_vdd_4500.txt",
    "4V0_r0_vdd_4500.txt"
];

// DOM Elements
const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('file-input');
const fileList = document.getElementById('file-list');
const btnPreview = document.getElementById('btn-preview');
const btnExport = document.getElementById('btn-export');
const btnClear = document.getElementById('btn-clear');
const previewContent = document.getElementById('preview-container');
const themeSelect = document.getElementById('theme-select');

// Event Listeners
dropZone.addEventListener('click', () => fileInput.click());
dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.classList.add('drag-over');
});
dropZone.addEventListener('dragleave', () => dropZone.classList.remove('drag-over'));
dropZone.addEventListener('drop', handleDrop);
fileInput.addEventListener('change', handleFileSelect);
btnPreview.addEventListener('click', updatePreview);
btnExport.addEventListener('click', exportData);

function clearAllData() {
    previewContent.innerHTML = '';
    mergedData = null;
    uploadedFiles = [];
    renderFileList();
    document.getElementById('directory-info').style.display = 'none'; // 清除時隱藏
    updateDiffOptions([]); // Clear diff options
}

btnClear.addEventListener('click', clearAllData);
themeSelect.addEventListener('change', (e) => {
    document.body.className = `theme-${e.target.value}`;
    saveSettings();
});

// Zoom Control
const zoomSlider = document.getElementById('zoom-slider');
const zoomValue = document.getElementById('zoom-value');

zoomSlider.addEventListener('input', (e) => {
    const val = e.target.value;
    zoomValue.textContent = `${Math.round(val * 100)}%`;
    const table = previewContent.querySelector('table');
    if (table) {
        table.style.zoom = val;
    }
});

// Zoom buttons
const btnZoomOut = document.getElementById('btn-zoom-out');
const btnZoomIn = document.getElementById('btn-zoom-in');
const btnZoomReset = document.getElementById('btn-zoom-reset');

btnZoomOut.addEventListener('click', () => {
    let currentZoom = parseFloat(zoomSlider.value);
    let newZoom = Math.max(0.5, currentZoom - 0.1);
    zoomSlider.value = newZoom;
    zoomSlider.dispatchEvent(new Event('input'));
});

btnZoomIn.addEventListener('click', () => {
    let currentZoom = parseFloat(zoomSlider.value);
    let newZoom = Math.min(2.0, currentZoom + 0.1);
    zoomSlider.value = newZoom;
    zoomSlider.dispatchEvent(new Event('input'));
});

btnZoomReset.addEventListener('click', () => {
    zoomSlider.value = 1.0;
    zoomSlider.dispatchEvent(new Event('input'));
});

// Settings Persistence
const SETTINGS_KEY = 'dump_data_tool_settings';

function saveSettings() {
    const settings = {
        theme: themeSelect.value,
        rowFilter: {
            enable: document.getElementById('row-filter-enable').checked,
            from: document.getElementById('row-from').value,
            to: document.getElementById('row-to').value,
            step: document.getElementById('row-step').value
        },
        colFilter: {
            enable: document.getElementById('col-filter-enable').checked,
            from: document.getElementById('col-from').value,
            to: document.getElementById('col-to').value,
            step: document.getElementById('col-step').value
        },
        highlight: {
            enable: document.getElementById('highlight-enable').checked,
            patterns: [
                { pat: document.getElementById('pattern-1').value, col: document.getElementById('color-1').value },
                { pat: document.getElementById('pattern-2').value, col: document.getElementById('color-2').value },
                { pat: document.getElementById('pattern-3').value, col: document.getElementById('color-3').value }
            ],
            diff: {
                enable: document.getElementById('diff-enable').checked,
                refCol: document.getElementById('diff-ref-col').value,
                color: document.getElementById('diff-color').value
            },
            ecc: {
                enable: document.getElementById('ecc-enable').checked,
                color: document.getElementById('ecc-color').value
            }
        }
    };
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}

function loadSettings() {
    const saved = localStorage.getItem(SETTINGS_KEY);
    if (!saved) return;

    try {
        const settings = JSON.parse(saved);

        // Theme
        if (settings.theme) {
            themeSelect.value = settings.theme;
            document.body.className = `theme-${settings.theme}`;
        }

        // Row Filter
        if (settings.rowFilter) {
            document.getElementById('row-filter-enable').checked = settings.rowFilter.enable;
            document.getElementById('row-from').value = settings.rowFilter.from || '';
            document.getElementById('row-to').value = settings.rowFilter.to || '';
            document.getElementById('row-step').value = settings.rowFilter.step || '';
        }

        // Col Filter
        if (settings.colFilter) {
            document.getElementById('col-filter-enable').checked = settings.colFilter.enable;
            document.getElementById('col-from').value = settings.colFilter.from || '';
            document.getElementById('col-to').value = settings.colFilter.to || '';
            document.getElementById('col-step').value = settings.colFilter.step || '';
        }

        // Highlights
        if (settings.highlight) {
            document.getElementById('highlight-enable').checked = settings.highlight.enable;

            if (settings.highlight.patterns) {
                settings.highlight.patterns.forEach((p, i) => {
                    const idx = i + 1;
                    if (document.getElementById(`pattern-${idx}`)) {
                        document.getElementById(`pattern-${idx}`).value = p.pat || '';
                        document.getElementById(`color-${idx}`).value = p.col || '#D3D3D3';
                    }
                });
            }

            if (settings.highlight.diff) {
                document.getElementById('diff-enable').checked = settings.highlight.diff.enable;
                // Save to global variable to apply later when options are available
                savedDiffRefCol = settings.highlight.diff.refCol;
                document.getElementById('diff-color').value = settings.highlight.diff.color || '#FF0000';
            }

            if (settings.highlight.ecc) {
                document.getElementById('ecc-enable').checked = settings.highlight.ecc.enable;
                document.getElementById('ecc-color').value = settings.highlight.ecc.color || '#FFA0A0';
            }
        }
    } catch (e) {
        console.error('Failed to load settings:', e);
    }
}

// Attach listeners to all inputs for auto-saving
const allInputs = document.querySelectorAll('input, select');
allInputs.forEach(input => {
    if (input.id !== 'file-input') { // Exclude file input
        input.addEventListener('change', saveSettings);
        input.addEventListener('input', saveSettings); // Save on typing too? Maybe just change for now to avoid spam. Let's stick to change for text inputs to be safe, or debounce. 'change' is good enough for text inputs (on blur).
    }
});

// Load settings on startup
loadSettings();

// Helper: Update Diff Options
function updateDiffOptions(columns) {
    const select = document.getElementById('diff-ref-col');
    const currentVal = select.value;
    
    select.innerHTML = '';
    
    if (!columns || columns.length === 0) {
        const option = document.createElement('option');
        option.text = 'Load files first';
        option.disabled = true;
        option.selected = true;
        select.add(option);
        return;
    }
    
    columns.forEach(col => {
        const option = document.createElement('option');
        option.value = col;
        option.text = col;
        select.add(option);
    });
    
    // Restore selection
    // Priority: Saved setting > Current Value (if valid) > First Option
    if (savedDiffRefCol && columns.includes(savedDiffRefCol)) {
        select.value = savedDiffRefCol;
    } else if (currentVal && columns.includes(currentVal)) {
        select.value = currentVal;
    } else {
        select.value = columns[0];
    }
    
    // Update saved setting to match what we actually selected (if it changed)
    // This prevents "ghost" settings
    if (select.value !== savedDiffRefCol) {
        // savedDiffRefCol = select.value; // Optional: update internal state
        // saveSettings(); // Optional: trigger save? Maybe better to wait for user interaction.
    }
}

// File Handling
function handleDrop(e) {
    e.preventDefault();
    dropZone.classList.remove('drag-over');
    const files = Array.from(e.dataTransfer.files).filter(f => f.name.endsWith('.txt'));
    processFiles(files);
}

function handleFileSelect(e) {
    const files = Array.from(e.target.files);
    processFiles(files);
    fileInput.value = ''; // Reset input
}

// async function processFiles(files) {
//     for (const file of files) {
//         // Check for duplicates
//         let name = file.name;
//         let counter = 2;
//         while (uploadedFiles.some(f => f.name === name)) {
//             const baseName = file.name.replace(/\.txt$/i, '');
//             name = `${baseName} (${counter}).txt`;
//             counter++;
//         }

//         const text = await file.text();
//         const df = parseFileToDf(text, name);

//         if (df) {
//             uploadedFiles.push({ name, content: text, df });
//             addFileToList(name);
//         }
//     }
// }
async function processFiles(files) {
    if (files.length === 0) return;

    // Clear existing data before processing new upload
    clearAllData();

    // 顯示目錄資訊：從第一個檔案的 webkitRelativePath 提取根資料夾名稱
    const firstFile = files[0];
    if (firstFile.webkitRelativePath) {
        const pathParts = firstFile.webkitRelativePath.split('/');
        const rootFolder = pathParts[0]; // 取得選擇的資料夾名稱
        document.getElementById('dir-name').textContent = `📁 ${rootFolder}`;
        document.getElementById('directory-info').style.display = 'block';
    }

    // 將選取的檔案轉換成一個 Map，方便透過檔名快速查找
    const fileMap = {};
    for (const file of files) {
        fileMap[file.name] = file;
    }

    // 依照 targetOrder 的順序進行處理
    for (const fileName of targetOrder) {
        const file = fileMap[fileName];
        
        if (file) {
            // 檢查是否已經在 uploadedFiles 中 (避免重複上傳)
            if (uploadedFiles.some(f => f.name === file.name)) continue;

            const text = await file.text();
            const df = parseFileToDf(text, file.name);

            if (df) {
                uploadedFiles.push({ name: file.name, content: text, df });
                addFileToList(file.name);
            }
        }
    }
    
    // 選項：讀取完畢後自動執行預覽 (如果您希望選完資料夾就直接顯示)
    if (uploadedFiles.length > 0) updatePreview(); 
}

function addFileToList(name) {
    const li = document.createElement('li');
    li.className = 'file-item';
    li.innerHTML = `
        <span>${name}</span>
        <button class="remove-btn" onclick="removeFile('${name}')">&times;</button>
    `;
    fileList.appendChild(li);
}

window.removeFile = function (name) {
    const idx = uploadedFiles.findIndex(f => f.name === name);
    if (idx !== -1) {
        uploadedFiles.splice(idx, 1);
        renderFileList();
        if (uploadedFiles.length === 0) {
            mergedData = null;
            previewContent.innerHTML = '';
            updateDiffOptions([]);
        }
    }
};

function renderFileList() {
    fileList.innerHTML = '';
    uploadedFiles.forEach(f => addFileToList(f.name));
}

// Core Logic: Parse File (Replicates read_files_to_df)
function parseFileToDf(text, filename) {
    const lines = text.trim().split(/\r?\n/);
    if (lines.length < 2) return null;

    // Filter out empty lines
    const validLines = lines.filter(l => l.trim() !== '');
    if (validLines.length < 2) return null;

    let df = {
        index: [],
        columns: [],
        data: {} // colName -> [values]
    };

    // Check last row for A\mV
    let lastRow = validLines[validLines.length - 1].trim().split(/\s+/);
    if (lastRow[0] === 'A\\mV') {
        validLines.pop();
    }

    // Check first row for header
    let firstRow = validLines[0].trim().split(/\s+/);
    let hasHeader = firstRow[0] === 'A\\mV';
    let dataStartIndex = 0;

    if (hasHeader) {
        df.columns = firstRow.slice(1);
        dataStartIndex = 1;
    } else {
        // Use filename as column name
        df.columns = [filename.replace(/\.txt$/i, '')];
        dataStartIndex = 0;
    }

    // Initialize data arrays
    df.columns.forEach(col => df.data[col] = []);

    // Process data rows
    for (let i = dataStartIndex; i < validLines.length; i++) {
        const parts = validLines[i].trim().split(/\s+/);
        if (parts.length < 1) continue;

        // First column is Hex Index
        const indexHex = parts[0];
        const indexInt = parseInt(indexHex, 16);

        if (isNaN(indexInt)) continue;

        df.index.push(indexInt);

        // Remaining columns
        const values = parts.slice(1);
        df.columns.forEach((col, idx) => {
            df.data[col].push(values[idx] || '');
        });
    }

    return df;
}

// Core Logic: Merge Data
function mergeData() {
    if (uploadedFiles.length === 0) return null;

    let merged = {
        index: [],
        columns: [],
        data: {}
    };

    // Collect all unique indices and sort them
    let allIndices = new Set();
    uploadedFiles.forEach(f => {
        f.df.index.forEach(idx => allIndices.add(idx));
    });
    merged.index = Array.from(allIndices).sort((a, b) => a - b);

    // Merge columns
    uploadedFiles.forEach(f => {
        f.df.columns.forEach(col => {
            // Handle duplicate column names
            let newCol = col;
            let counter = 2;
            while (merged.columns.includes(newCol)) {
                newCol = `${col}_${counter}`;
                counter++;
            }
            merged.columns.push(newCol);
            merged.data[newCol] = new Array(merged.index.length).fill('');

            // Fill data aligned by index
            const fileIndexMap = new Map(); // index -> row position in file
            f.df.index.forEach((val, pos) => fileIndexMap.set(val, pos));

            merged.index.forEach((idx, pos) => {
                if (fileIndexMap.has(idx)) {
                    const originalPos = fileIndexMap.get(idx);
                    merged.data[newCol][pos] = f.df.data[col][originalPos];
                }
            });
        });
    });

    return merged;
}

// Preview Generation
function updatePreview() {
    if (uploadedFiles.length === 0) {
        alert('Please upload files first.');
        return;
    }

    mergedData = mergeData();
    if (!mergedData) return;

    // Update Diff Dropdown with available columns
    updateDiffOptions(mergedData.columns);

    // Get Filter Parameters
    const rowFilterEnable = document.getElementById('row-filter-enable').checked;
    const rowFrom = parseInt(document.getElementById('row-from').value, 16);
    const rowTo = parseInt(document.getElementById('row-to').value, 16);
    const rowStep = parseInt(document.getElementById('row-step').value, 16) || 1;

    const colFilterEnable = document.getElementById('col-filter-enable').checked;
    const colFrom = parseInt(document.getElementById('col-from').value, 10);
    const colTo = parseInt(document.getElementById('col-to').value, 10);
    const colStep = parseInt(document.getElementById('col-step').value, 10) || 1;

    // Filter Rows (Indices)
    let displayIndices = [];

    if (rowFilterEnable && !isNaN(rowFrom) && !isNaN(rowTo)) {
        for (let i = 0; i < mergedData.index.length; i++) {
            // Filter by Row Position (0-based) as per previous analysis
            if (i >= rowFrom && i <= rowTo) {
                if ((i - rowFrom) % rowStep === 0) {
                    displayIndices.push(i);
                }
            }
        }
    } else {
        displayIndices = mergedData.index.map((_, i) => i);
    }

    // Filter Columns
    let displayCols = mergedData.columns;
    if (colFilterEnable && !isNaN(colFrom) && !isNaN(colTo)) {
        displayCols = [];
        for (let i = 0; i < mergedData.columns.length; i++) {
            // Convert 1-based input to 0-based index
            const checkIdx = i + 1;
            if (checkIdx >= colFrom && checkIdx <= colTo) {
                if ((checkIdx - colFrom) % colStep === 0) {
                    displayCols.push(mergedData.columns[i]);
                }
            }
        }
    }

    // Build HTML Table
    const idxHeader = 'A\\mV';
    let html = '<table>';

    // Header Row
    html += '<thead><tr>';
    html += `<th>${escapeHtml(idxHeader)}</th>`; // Sticky Index Header
    displayCols.forEach(col => {
        html += `<th>${escapeHtml(col)}</th>`;
    });
    html += '</tr></thead>';

    // Body
    html += '<tbody>';
    displayIndices.forEach(rowIdx => {
        const idxVal = mergedData.index[rowIdx];
        const idxStr = idxVal.toString(16).toUpperCase().padStart(4, '0');

        html += `<tr data-row-idx="${rowIdx}">`;
        html += `<th>${idxStr}</th>`; // Sticky Index Column

        displayCols.forEach((col, cIdx) => {
            const val = mergedData.data[col][rowIdx] || '';
            html += `<td data-val="${val}" data-col-idx="${cIdx}">${escapeHtml(val)}</td>`;
        });
        html += '</tr>';
    });
    html += '</tbody></table>';

    previewContent.innerHTML = html;

    // Apply current zoom
    const table = previewContent.querySelector('table');
    if (table) {
        table.style.zoom = zoomSlider.value;
    }

    applyHighlights();
}

function applyHighlights() {
    const highlightEnable = document.getElementById('highlight-enable').checked;
    if (!highlightEnable) return;

    // Get Patterns
    const patterns = [];
    for (let i = 1; i <= 3; i++) {
        const pat = document.getElementById(`pattern-${i}`).value.trim();
        const col = document.getElementById(`color-${i}`).value;
        if (pat) patterns.push({ pat, col, id: i });
    }

    // Get ECC
    const eccEnable = document.getElementById('ecc-enable').checked;
    const eccColor = document.getElementById('ecc-color').value;

    // Get Diff Settings
    const diffEnable = document.getElementById('diff-enable').checked;
    const diffRefColName = document.getElementById('diff-ref-col').value;
    const diffColor = document.getElementById('diff-color').value;

    // Apply to all data cells (td)
    const cells = previewContent.querySelectorAll('td');

    // Reset styles first
    cells.forEach(cell => {
        cell.style.color = '';
        cell.style.fontWeight = '';
    });

    // 1. Pattern Highlight
    cells.forEach(cell => {
        const text = cell.getAttribute('data-val');
        if (!text) return;

        patterns.forEach(p => {
            if (text.includes(p.pat)) {
                cell.style.color = p.col;
                cell.style.fontWeight = 'bold';
            }
        });
    });

    // 2. Diff Highlight
    if (diffEnable && diffRefColName && mergedData.data[diffRefColName]) {
        const rows = previewContent.querySelectorAll('tbody tr');
        rows.forEach(row => {
            const rowIdx = row.getAttribute('data-row-idx');
            // Get reference value for this specific row from the source data
            const refVal = mergedData.data[diffRefColName][rowIdx];

            if (refVal !== undefined && refVal !== null) {
                const rowCells = row.querySelectorAll('td');
                rowCells.forEach(cell => {
                    const val = cell.getAttribute('data-val');
                    // We must determine if this cell belongs to the reference column
                    // Since we have data-col-idx, we can check display columns?
                    // But display columns logic is inside updatePreview.
                    // Easier check: The table header has the column name?
                    // We can assume we want to diff everything *except* the reference column.
                    // But if the reference column is displayed, we shouldn't highlight it against itself.
                    // We can check if the value matches first. If match, no highlight. 
                    // (Self-comparison always matches, so it won't highlight, which is correct!)
                    
                    if (val !== refVal) {
                        cell.style.color = diffColor;
                        cell.style.fontWeight = 'bold';
                    }
                });
            }
        });
    }

    // 3. ECC Check
    if (eccEnable) {
        cells.forEach(cell => {
             const text = cell.getAttribute('data-val');
             if (!text) return;

             const parts = text.split('_');
             if (parts.length >= 3) {
                 const a = parts[0];
                 const b = parts[1];
                 if (a.toUpperCase() !== b.toUpperCase()) {
                     cell.style.color = eccColor;
                     cell.style.fontWeight = 'bold';
                 }
             }
        });
    }
}


async function exportData() {
    if (!mergedData) {
        alert('No data to export.');
        return;
    }

    // For export, we need to reconstruct the text format (aligned columns)
    const table = previewContent.querySelector('table');
    if (!table) return;

    let text = '';
    const rows = table.querySelectorAll('tr');

    // First pass: Calculate column widths for alignment
    const colWidths = [];
    // Header row
    const headerCells = rows[0].querySelectorAll('th');
    headerCells.forEach((cell, i) => {
        colWidths[i] = cell.innerText.length;
    });

    // Data rows
    for (let i = 1; i < rows.length; i++) {
        const cells = rows[i].querySelectorAll('th, td');
        cells.forEach((cell, j) => {
            const len = cell.innerText.length;
            if (len > colWidths[j]) colWidths[j] = len;
        });
    }

    // Second pass: Build string
    rows.forEach(row => {
        const cells = row.querySelectorAll('th, td');
        const lineParts = [];
        cells.forEach((cell, i) => {
            let val = cell.innerText;
            if (i === 0) {
                // Index
                lineParts.push(val.padStart(4)); // Minimum 4 chars
            } else {
                lineParts.push(val.padEnd(colWidths[i]));
            }
        });
        text += lineParts.join('  ') + '\n';
    });

    // File Saving Logic
    try {
        if (window.showSaveFilePicker) {
            const handle = await window.showSaveFilePicker({
                suggestedName: 'dump_data_export.txt',
                types: [{
                    description: 'Text Files',
                    accept: { 'text/plain': ['.txt'] },
                }],
            });
            const writable = await handle.createWritable();
            await writable.write(text);
            await writable.close();
        } else {
            // Fallback
            const filename = prompt('Enter filename to save:', 'dump_data_export.txt');
            if (filename) {
                const blob = new Blob([text], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = filename;
                a.click();
                URL.revokeObjectURL(url);
            }
        }
    } catch (err) {
        if (err.name !== 'AbortError') {
            console.error('Export failed:', err);
            alert('Failed to save file.');
        }
    }
}

function escapeHtml(text) {
    return text
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}
