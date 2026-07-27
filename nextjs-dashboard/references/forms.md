# Forms (react-hook-form + Zod + shadcn Form)

Pengganti Ant Design `Form`. Validasi pakai **Zod schema yang sama dengan server** (SSOT) → tak ada drift antara validasi client & server.

Butuh: `pnpm dlx shadcn@latest add form input select checkbox textarea button dialog` · `pnpm add react-hook-form @hookform/resolvers zod`

> `shadcn add form` menambahkan wrapper `Form*` di atas react-hook-form (`FormField`, `FormItem`, `FormLabel`, `FormControl`, `FormMessage`).

---

## 1. Schema = SSOT (reuse dari `lib/validations`)

```ts
// src/lib/validations/user.ts  (sudah dipakai server — lihat nextjs-core/mongodb-mongoose.md)
import { z } from "zod";

export const userFormSchema = z.object({
  name: z.string().trim().min(1, "Nama wajib diisi").max(120),
  email: z.string().trim().email("Email tidak valid"),
  role: z.enum(["admin", "manager", "user"]),
});

export type UserFormValues = z.infer<typeof userFormSchema>;
```

---

## 2. Form component

```tsx
// src/components/forms/user-form.tsx
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { userFormSchema, type UserFormValues } from "@/lib/validations/user";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Form, FormControl, FormField, FormItem, FormLabel, FormMessage, FormDescription,
} from "@/components/ui/form";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";

interface UserFormProps {
  defaultValues?: Partial<UserFormValues>;
  onSubmit: (values: UserFormValues) => void;
  isSubmitting?: boolean;
  submitLabel?: string;
}

export function UserForm({ defaultValues, onSubmit, isSubmitting, submitLabel = "Simpan" }: UserFormProps) {
  const form = useForm<UserFormValues>({
    resolver: zodResolver(userFormSchema),
    defaultValues: { name: "", email: "", role: "user", ...defaultValues },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-5">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Nama</FormLabel>
              <FormControl>
                <Input placeholder="Nama lengkap" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="nama@email.com" {...field} />
              </FormControl>
              <FormDescription>Dipakai untuk login & notifikasi.</FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="role"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Role</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih role" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="admin">Admin</SelectItem>
                  <SelectItem value="manager">Manager</SelectItem>
                  <SelectItem value="user">User</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />

        <div className="flex justify-end gap-2">
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting ? "Menyimpan..." : submitLabel}
          </Button>
        </div>
      </form>
    </Form>
  );
}
```

Aturan:
- `FormMessage` menampilkan error validasi Zod otomatis (a11y: terhubung ke input via `aria`).
- `FormLabel` selalu ada (jangan placeholder-only — buruk untuk a11y).
- Tombol submit **disabled** saat `isSubmitting` → cegah double-submit.

---

## 3. Form dalam Dialog (pola CRUD)

```tsx
// src/app/(app)/users/user-form-dialog.tsx
"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";
import { UserForm } from "@/components/forms/user-form";
import { useCreateUser } from "@/hooks/use-users";

export function CreateUserDialog() {
  const [open, setOpen] = useState(false);
  const createUser = useCreateUser();

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Plus className="size-4" /> Tambah User
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Tambah User</DialogTitle>
          <DialogDescription>Isi data user baru di bawah ini.</DialogDescription>
        </DialogHeader>
        <UserForm
          isSubmitting={createUser.isPending}
          onSubmit={(values) =>
            createUser.mutate(
              { ...values, password: "changeme123" }, // contoh; sesuaikan flow
              { onSuccess: () => setOpen(false) },
            )
          }
        />
      </DialogContent>
    </Dialog>
  );
}
```

Untuk **edit**, pakai komponen `UserForm` yang sama dengan `defaultValues` dari data terpilih + mutation update.

---

## 4. Validasi client = server

Schema `userFormSchema` yang sama dipakai:
- **Client** → `zodResolver` (feedback instan, UX).
- **Server** → `.safeParse()` di route handler (keamanan; lihat `nextjs-core/mongodb-mongoose.md`).

Client validation itu UX; **server validation tetap wajib** — jangan pernah percaya input dari client.

---

## 5. Error server → field (opsional)

Kalau API balikin error per-field (mis. email duplikat 409), map ke form:

```ts
onError: (err) => {
  if (err instanceof ApiError && err.status === 409) {
    form.setError("email", { message: "Email sudah terdaftar" });
  } else {
    toast.error("Gagal menyimpan");
  }
}
```

---

## Checklist form (wajib)

- [ ] Schema Zod dipakai di client (resolver) **dan** server (safeParse)
- [ ] Setiap field punya `FormLabel` + `FormMessage`
- [ ] Submit disabled saat pending (anti double-submit)
- [ ] Feedback sukses/gagal via `sonner` / inline
- [ ] Error server per-field di-map via `form.setError`
- [ ] Dialog form: reset/close on success
- [ ] Keyboard & focus (shadcn Dialog + Form sudah a11y) terverifikasi
- [ ] Dark mode terverifikasi
