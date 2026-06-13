import type { InputProps } from "ra-core";
import { FieldTitle, useInput, useResourceContext } from "ra-core";
import type { UseEditorOptions } from "@tiptap/react";

import {
  FormControl,
  FormError,
  FormField,
  FormLabel,
} from "@/components/admin/form";
import { InputHelperText } from "@/components/admin/input-helper-text";
import { RichTextInputToolbar } from "@/components/rich-text-input/rich-text-input-toolbar";
import { MinimalTiptapEditor } from "@/components/rich-text-input/minimal-tiptap";

export type SimpleRichTextInputProps = InputProps & {
  className?: string;
  editorOptions?: Partial<UseEditorOptions>;
};

/**
 * Simple rich text editor input powered by TipTap.
 * 
 * This is a simplified version of the rich text input with fewer dependencies
 * and a more straightforward API.
 */
export const SimpleRichTextInput = (props: SimpleRichTextInputProps) => {
  const {
    className,
    defaultValue = "",
    disabled,
    editorOptions = {},
    helperText,
    label,
    readOnly,
    source,
    validate: _validateProp,
    format: _formatProp,
  } = props;
  const resource = useResourceContext(props);
  const { id, field, isRequired } = useInput({ ...props, source, defaultValue });

  return (
    <FormField id={id} className={className} name={field.name}>
      {label !== false && (
        <FormLabel>
          <FieldTitle
            label={label}
            source={source}
            resource={resource}
            isRequired={isRequired}
          />
        </FormLabel>
      )}
      <FormControl>
        <div>
          <MinimalTiptapEditor
            {...editorOptions}
            value={field.value ?? ""}
            onChange={(value) => {
              field.onChange(value);
            }}
            onBlur={() => {
              field.onBlur?.();
            }}
            output="html"
            editable={!disabled && !readOnly}
            toolbar={<RichTextInputToolbar />}
          />
        </div>
      </FormControl>
      <InputHelperText helperText={helperText} />
      <FormError />
    </FormField>
  );
};