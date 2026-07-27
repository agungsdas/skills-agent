# Data Table (TanStack Table + shadcn)

Pengganti Ant Design `Table`. Headless **TanStack Table v8** di-skin dengan shadcn `table`.
Data-heavy → **server-side pagination** (nyambung ke repository/API `{ data, meta }`). Semua state (loading/empty/error) wajib.

Butuh: `pnpm dlx shadcn@latest add table button dropdown-menu input skeleton badge alert-dialog` · `pnpm add @tanstack/react-table`

Density dashboard: kompak (`text-sm`, baris rapat) tapi tetap terbaca (lihat `nextjs-core/references/design-principles.md` §9).

---

## 1. Reusable DataTable (server-side pagination)

```tsx
// src/components/data-table/data-table.tsx
"use client";

import {
  flexRender,
  getCoreRowModel,
  useReactTable,
  type ColumnDef,
  type PaginationState,
} from "@tanstack/react-table";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { DataTablePagination } from "./data-table-pagination";
import { Skeleton } from "@/components/ui/skeleton";

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
  pageCount: number;
  pagination: PaginationState;
  onPaginationChange: (updater: React.SetStateAction<PaginationState>) => void;
  isLoading?: boolean;
  isError?: boolean;
  onRetry?: () => void;
  emptyState?: React.ReactNode;
}

export function DataTable<TData, TValue>({
  columns,
  data,
  pageCount,
  pagination,
  onPaginationChange,
  isLoading,
  isError,
  onRetry,
  emptyState,
}: DataTableProps<TData, TValue>) {
  const table = useReactTable({
    data,
    columns,
    pageCount,
    state: { pagination },
    onPaginationChange,
    manualPagination: true, // server yang paginasi
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="space-y-4">
      <div className="rounded-xl border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((hg) => (
              <TableRow key={hg.id}>
                {hg.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>

          <TableBody>
            {isLoading ? (
              // Loading = skeleton baris (bukan spinner tengah)
              Array.from({ length: pagination.pageSize }).map((_, i) => (
                <TableRow key={i}>
                  {columns.map((_c, j) => (
                    <TableCell key={j}>
                      <Skeleton className="h-5 w-full" />
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : isError ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-32 text-center">
                  <p className="text-sm text-muted-foreground">Gagal memuat data.</p>
                  {onRetry && (
                    <button onClick={onRetry} className="mt-2 text-sm font-medium underline underline-offset-4">
                      Coba lagi
                    </button>
                  )}
                </TableCell>
              </TableRow>
            ) : table.getRowModel().rows.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-32 text-center">
                  {emptyState ?? <span className="text-sm text-muted-foreground">Belum ada data.</span>}
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      <DataTablePagination table={table} />
    </div>
  );
}
```

---

## 2. Pagination controls

```tsx
// src/components/data-table/data-table-pagination.tsx
"use client";

import type { Table } from "@tanstack/react-table";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";

export function DataTablePagination<TData>({ table }: { table: Table<TData> }) {
  return (
    <div className="flex items-center justify-between">
      <p className="text-sm text-muted-foreground">
        Halaman {table.getState().pagination.pageIndex + 1} dari {table.getPageCount() || 1}
      </p>
      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.previousPage()}
          disabled={!table.getCanPreviousPage()}
        >
          <ChevronLeft className="size-4" /> Sebelumnya
        </Button>
        <Button variant="outline" size="sm" onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}>
          Berikutnya <ChevronRight className="size-4" />
        </Button>
      </div>
    </div>
  );
}
```

---

## 3. Column definitions (sortable header + cell + row actions)

```tsx
// src/app/(app)/users/columns.tsx
"use client";

import type { ColumnDef } from "@tanstack/react-table";
import { ArrowUpDown, MoreHorizontal } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { User } from "@/types/user";

export function getUserColumns(actions: {
  onEdit: (u: User) => void;
  onDelete: (u: User) => void;
}): ColumnDef<User>[] {
  return [
    {
      accessorKey: "name",
      header: ({ column }) => (
        <Button
          variant="ghost"
          className="-ml-3 h-8"
          onClick={() => column.toggleSorting(column.getIsSorted() === "asc")}
        >
          Nama <ArrowUpDown className="ml-2 size-3.5" />
        </Button>
      ),
      cell: ({ row }) => <span className="font-medium">{row.original.name}</span>,
    },
    { accessorKey: "email", header: "Email", cell: ({ row }) => <span className="text-muted-foreground">{row.original.email}</span> },
    {
      accessorKey: "role",
      header: "Role",
      cell: ({ row }) => <Badge variant="secondary" className="capitalize">{row.original.role}</Badge>,
    },
    {
      id: "actions",
      cell: ({ row }) => (
        <div className="text-right">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="size-8">
                <MoreHorizontal className="size-4" />
                <span className="sr-only">Aksi</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={() => actions.onEdit(row.original)}>Edit</DropdownMenuItem>
              <DropdownMenuItem variant="destructive" onClick={() => actions.onDelete(row.original)}>
                Hapus
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      ),
    },
  ];
}
```

> Sorting di atas contoh client-side (halaman aktif). Untuk dataset besar, pindah ke **server-side**: `manualSorting: true`, kirim `sort`/`order` ke API, dan sertakan di query key.

---

## 4. Toolbar (search server-side, debounced)

```tsx
// src/components/data-table/data-table-toolbar.tsx
"use client";

import { Search } from "lucide-react";
import { Input } from "@/components/ui/input";

export function DataTableToolbar({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="relative max-w-sm">
      <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
      <Input
        placeholder="Cari nama atau email..."
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="pl-9"
      />
    </div>
  );
}
```

---

## 5. Halaman lengkap (wiring TanStack Query + confirm delete)

```tsx
// src/app/(app)/users/users-table.tsx
"use client";

import { useMemo, useState } from "react";
import type { PaginationState } from "@tanstack/react-table";
import { useUsers, useDeleteUser } from "@/hooks/use-users";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { DataTable } from "@/components/data-table/data-table";
import { DataTableToolbar } from "@/components/data-table/data-table-toolbar";
import { getUserColumns } from "./columns";
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import type { User } from "@/types/user";

export function UsersTable() {
  const [keyword, setKeyword] = useState("");
  const debouncedKeyword = useDebouncedValue(keyword, 300);
  const [pagination, setPagination] = useState<PaginationState>({ pageIndex: 0, pageSize: 20 });
  const [toDelete, setToDelete] = useState<User | null>(null);

  const { data, isLoading, isError, refetch } = useUsers({
    page: pagination.pageIndex + 1,
    perPage: pagination.pageSize,
    keyword: debouncedKeyword,
  });
  const deleteUser = useDeleteUser();

  const columns = useMemo(
    () => getUserColumns({ onEdit: () => {}, onDelete: setToDelete }),
    [],
  );

  const pageCount = data?.meta?.total_page ?? 0;

  return (
    <div className="space-y-4">
      <DataTableToolbar value={keyword} onChange={setKeyword} />

      <DataTable
        columns={columns}
        data={data?.data ?? []}
        pageCount={pageCount}
        pagination={pagination}
        onPaginationChange={setPagination}
        isLoading={isLoading}
        isError={isError}
        onRetry={refetch}
      />

      <AlertDialog open={!!toDelete} onOpenChange={(o) => !o && setToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Hapus user?</AlertDialogTitle>
            <AlertDialogDescription>
              &ldquo;{toDelete?.name}&rdquo; akan dihapus. Tindakan ini tidak bisa dibatalkan.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Batal</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (toDelete) deleteUser.mutate(toDelete.id, { onSettled: () => setToDelete(null) });
              }}
            >
              Hapus
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
```

> `useDebouncedValue` = custom hook kecil (300ms) di `hooks/` untuk menahan request saat mengetik.

---

## Checklist data table (wajib)

- [ ] Server-side pagination (`manualPagination`, `pageCount` dari `meta.total_page`)
- [ ] Loading = skeleton baris; empty & error state ada (error + retry)
- [ ] Search debounced → query param server (bukan filter client)
- [ ] Row action destruktif lewat `AlertDialog` konfirmasi
- [ ] `colSpan` benar untuk state kosong/error
- [ ] Density kompak tapi terbaca; warna via token
- [ ] Dark mode & keyboard (dropdown/dialog shadcn sudah a11y) terverifikasi
